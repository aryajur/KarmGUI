-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application main file forms the frontend and handles the GUI
-- Author:      Milind Gupta
-- Created:     1/13/2012
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
--package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
package.cpath = ";?.dll;?.so;"

require("wx")

-- DO ALL CONFIGURATION
Karm = {}
-- Table to store all the Spores data 
Karm.SporeData = {}


-- Creating GUI the main table containing all the GUI objects and data
Karm.GUI = {
	-- Node Colors
	nodeForeColor = {Red=0,Green=0,Blue=0},
	nodeBackColor = {Red=255,Green=255,Blue=255},
	-- Gantt Colors
	noScheduleColor = {Red=210,Green=210,Blue=210},
	ScheduleColor = {Red=0,Green=180,Blue=215},
	emptyDayColor = {Red=255,Green=255,Blue=255},
	sunDayOffset = {Red = 30, Green=30, Blue = 30},
	bubbleOffset = {Red = 20, Green=20, Blue = 20},
	defaultColor = {Red=0,Green=0,Blue=0},
	highLightColor = {Red=120,Green=120,Blue=120},
	
	
	-- Task status colors
	-- Main Menu
	MainMenu = {
					-- 1st Menu
					{	
						Text = "&File", Menu = {
												{Text = "E&xit\tCtrl-x", HelpText = "Quit the program", Code = "Karm.GUI.frame:Close(true)"}
										}
					},
					-- 2nd Menu
					{	
						Text = "&Help", Menu = {
												{Text = "&About\tCtrl-A", HelpText = "About Karm", Code = "wx.wxMessageBox('Karm is the Task and Project management application for everybody.\\n Version: '..Karm.Globals.KARM_VERSION, 'About Karm',wx.wxOK + wx.wxICON_INFORMATION,Karm.GUI.frame)"}
										}
					}
	}
}

Karm.GUI.initFrameW, Karm.GUI.initFrameH = wx.wxDisplaySize()
Karm.GUI.initFrameW = 0.75*Karm.GUI.initFrameW
Karm.GUI.initFrameH = 0.75*Karm.GUI.initFrameH
Karm.GUI.initFrameW = Karm.GUI.initFrameW - Karm.GUI.initFrameW%1
Karm.GUI.initFrameH = Karm.GUI.initFrameH - Karm.GUI.initFrameH%1


setmetatable(Karm.GUI,{__index = _G})

-- Global Declarations
Karm.Globals = {
	ROOTKEY = "T0",
	KARM_VERSION = "1.12.08.13",
	PriorityList = {'1','2','3','4','5','6','7','8','9'},
	StatusList = {'Not Started','On Track','Behind','Done','Obsolete'},
	StatusNodeColor = {
				{	ForeColor = {Red=100,Green=100,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=0,Green=0,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=230,Green=0,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=0,Green=0,Blue=230},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=200,Green=200,Blue=200},
					BackColor = {Red=255,Green=255,Blue=255}
				}
	},
	NoDateStr = "__NO_DATE__",
	NoTagStr = "__NO_TAG__",
	NoAccessIDStr = "__NO_ACCESS__",
	NoCatStr = "__NO_CAT__",
	NoSubCatStr = "__NO_SUBCAT__",
	NoPriStr = "__NO_PRI__",
	__DEBUG = true,		-- For debug mode
	PlanningMode = false,	-- Flag to indicate Schedule Planning mode is on.
	unsavedSpores = {},	-- To store list of unsaved Spores
	safeenv = {},
	UserIDPattern = "%'([%w%.%_%,]+)%'"
}

-- Generate a unique new wxWindowID
do
	local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
	function Karm.NewID()
	    ID_IDCOUNTER = ID_IDCOUNTER + 1
	    return ID_IDCOUNTER
	end
end

-- FINISH CONFIGURATION

-- INCLUDE ALL CODE

-- Include the XML handling module
require("LuaXml")

-- Karm files
require("Filter")
require("DataHandler")
Karm.GUI.FilterForm = require("FilterForm")		-- Containing all Filter Form GUI code
Karm.GUI.TaskForm = require("TaskForm")		-- Containing all Task Form GUI code

-- FINISH CODE INCLUSION

do
	local IDMap = {}	-- Map from wxID to object (used to handle events)
	-- Metatable to define a node object's behaviour
	local nodeMeta = {__metatable = "Hidden, Do not change!"}
	local taskTreeINT = {__metatable = "Hidden, Do not change!"} 
	
	-- Function References
	local onScrollTree, onScrollGantt, labelClick, cellClick, horSashAdjust, widgetResize, refreshGantt, dispTask, dispGantt
	local cellClickCallBack, ganttCellClick, ganttLabelClick, ganttCellDblClick, onRowResizeGantt, onRowResizeTree

	-- Function to return the iterator function to iterate over all taskTree Nodes 
	-- This the function to be used in a Generic for
	function taskTreeINT.tpairs(taskTree)
		return taskTreeINT.nextNode, taskTree, nil
	end
	
	-- Iterator for all nodes will give the effect of iterating over all the tasks in the task tree sequentially as if the whole tree is expanded
	function taskTreeINT.nextNode(taskTree,index)
		-- index is the index of the node whose next node this function returns
		local i = index
		if not i then
			if not taskTreeINT[taskTree].Roots[1] then
				return nil,nil
			else
				return nodeMeta[taskTreeINT[taskTree].Roots[1]].Key, taskTreeINT[taskTree].Roots[1]
			end
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if this node has children
		if nodeMeta[oTree.Nodes[i]].FirstChild then
			return nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key, nodeMeta[oTree.Nodes[i]].FirstChild
		end
		-- No children so only way is next sibling or parents
		while oTree.Nodes[i] do
			if nodeMeta[oTree.Nodes[i]].Next then
				return nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key, nodeMeta[oTree.Nodes[i]].Next
			else
				-- No next siblings so go up a level and continue
				if nodeMeta[oTree.Nodes[i]].Parent then
					i = nodeMeta[nodeMeta[oTree.Nodes[i]].Parent].Key
				else
					i = nil
				end
			end
		end		-- while oTree.Nodes[i] do ends
	end
	
	-- Function to return the iterator function to iterate over only visible taskTree Nodes
	function taskTreeINT.tvpairs(taskTree)
		-- Note if taskTreeINT.update = false then the results of this iterator may not be in sync with what is seen on the GUI
		return taskTreeINT.nextVisibleNode, taskTree, nil
	end
	
	-- This iterator function totally relies on the presence of Row and Expanded Attributes
	-- From the given index it goes down only if the Expanded attribute is true and only gives a visible node if its Row attribute is present
	function taskTreeINT.nextVisibleNode(taskTree, index)
		-- index is the index of the node whose next node this function returns
		local i = index
		if not i then
			if not taskTreeINT[taskTree].Roots[1] then
				return nil,nil
			else
				return nodeMeta[taskTreeINT[taskTree].Roots[1]].Key, taskTreeINT[taskTree].Roots[1]
			end
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if this node is has children and is expanded
		if nodeMeta[oTree.Nodes[i]].FirstChild and nodeMeta[oTree.Nodes[i]].Expanded and nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Row then
			return nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key, nodeMeta[oTree.Nodes[i]].FirstChild
		elseif nodeMeta[oTree.Nodes[i]].FirstChild and nodeMeta[oTree.Nodes[i]].Expanded then
			return taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key)
		end
		-- No children visible so only way is next sibling or parents
		while oTree.Nodes[i] do
			if nodeMeta[oTree.Nodes[i]].Next and nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Row then
				return nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key, nodeMeta[oTree.Nodes[i]].Next
			elseif nodeMeta[oTree.Nodes[i]].Next then
				return taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key)
			else
				-- No next siblings so go up a level and continue
				if nodeMeta[oTree.Nodes[i]].Parent then
					i = nodeMeta[nodeMeta[oTree.Nodes[i]].Parent].Key
				else
					i = nil
				end
			end
		end		-- while oTree.Nodes[i] do ends					
	end
	
	function taskTreeINT.associateEventFunc(taskTree,funcTable)
		taskTreeINT[taskTree].cellClickCallBack = funcTable.cellClickCallBack or taskTreeINT[taskTree].cellClickCallBack
		taskTreeINT[taskTree].ganttCellClickCallBack = funcTable.ganttCellClickCallBack or taskTreeINT[taskTree].ganttCellClickCallBack
		taskTreeINT[taskTree].rowLabelClickCallBack = funcTable.rowLabelClickCallBack or taskTreeINT[taskTree].rowLabelClickCallBack
		taskTreeINT[taskTree].ganttRowLabelClickCallBack = funcTable.ganttRowLabelClickCallBack or taskTreeINT[taskTree].ganttRowLabelClickCallBack
		taskTreeINT[taskTree].ganttCellDblClickCallBack = funcTable.ganttCellDblClickCallBack or taskTreeINT[taskTree].ganttCellDblClickCallBack
	end

	function taskTreeINT.dateRangeChange(o,startDate,finDate)
		-- Clear the GanttGrid
		taskTreeINT[o].ganttGrid:DeleteRows(0,o.ganttGrid:GetNumberRows())
		taskTreeINT[o].ganttGrid:DeleteCols(0,o.ganttGrid:GetNumberCols())
		local currDate = startDate
		local count = 0
		local corner = taskTreeINT[o].ganttGrid:GetGridCornerLabelWindow()
		-- Add the Month and year in the corner
		local sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
		local textLabel = wx.wxStaticText(corner, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		textLabel:SetLabel(startDate:Format("%b %Y"))
		--textLabel:SetBackgroundColour(wx.wxColour(0,0,0))
		sizer:Add(textLabel, 1, wx.wxLEFT+wx.wxRIGHT+wx.wxALIGN_CENTRE_VERTICAL, 3)
		--corner:SetBackgroundColour(wx.wxColour(0,0,0))	
		corner:SetSizer(sizer)
		corner:Layout()	
		while not currDate:IsLaterThan(finDate) do
			taskTreeINT[o].ganttGrid:InsertCols(count)
			-- set the column labels
			taskTreeINT[o].ganttGrid:SetColLabelValue(count,string.sub(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y")),-2,-1)..
			    string.sub(Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))),1,1))
			taskTreeINT[o].ganttGrid:AutoSizeColumn(count)
			--taskTreeINT[o].ganttGrid:SetColLabelValue(count,string.sub(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y")),-5,-1))
			currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
			count = count + 1
		end
		taskTreeINT[o].startDate = startDate:Subtract(wx.wxDateSpan(0,0,0,count))
		taskTreeINT[o].finDate = finDate		
		refreshGantt(o)
	end
	
	function taskTreeINT.layout(taskTree)
		local oTree = taskTreeINT[taskTree]
		oTree.treeGrid:AutoSizeColumn(0)
	    oTree.treeGrid:SetColSize(1,oTree.horSplitWin:GetSashPosition()-oTree.treeGrid:GetColSize(0)-oTree.treeGrid:GetRowLabelSize(0))	
	end
	
	function taskTreeINT.disablePlanningMode(taskTree)
		local oTree = taskTreeINT[taskTree]
		oTree.Planning = nil
		-- Update all the tasks in the planning mode in the UI to remove the planning schedule
		for i = 1,#oTree.taskList do
			if oTree.Nodes[oTree.taskList[i].TaskID].Row then
				dispGantt(taskTree,oTree.Nodes[oTree.taskList[i].TaskID].Row,false,oTree.Nodes[oTree.taskList[i].TaskID])
			end
		end 
		oTree.taskList = nil
	end
	
	-- Function to enable the planning mode
	-- Type = "NORMAL" - Planning for normal schedules
	-- Type = "WORKDONE" - Planning for the actual work done schedule
	function taskTreeINT.enablePlanningMode(taskTree, taskList, type)
		local oTree = taskTreeINT[taskTree]
		taskList = taskList or {}
		type = type or "NORMAL"
		if type ~= "NORMAL" and type ~= "WORKDONE" then
			error("enablePlanningMode: Planning type should either be 'NORMAL' or 'WORKDONE'.",2)
		end
		oTree.Planning = type
		if not oTree.taskList then
			oTree.taskList = {}
			-- Check if there are tasks with Planning
			for i,v in taskTreeINT.tpairs(taskTree) do
				if v.Task and v.Task.Planning then
					oTree.taskList[#oTree.taskList + 1] = v.Task
				end
			end		-- Looping through all the nodes ends
		end
		-- Refresh the existing tasks in the taskList
		for j = 1,#oTree.taskList do
			if oTree.Nodes[oTree.taskList[j].TaskID]:MakeVisible() then
				dispGantt(taskTree,oTree.Nodes[oTree.taskList[j].TaskID].Row,false,oTree.Nodes[oTree.taskList[j].TaskID])
			end
		end
		for i = 1,#taskList do
			-- Check whether the task already exist in the taskList
			local found = false
			for j = 1,#oTree.taskList do
				if oTree.taskList[j] == taskList[i] then
					found = true
					break
				end
			end
			if not found then
				oTree.taskList[#oTree.taskList + 1] = taskList[i] 
				local dateList
				if type == "NORMAL" then
					-- Copy over the latest schedule to the planning period
					dateList = Karm.TaskObject.getLatestScheduleDates(taskList[i])
				else
					-- Copy over the work done dates to the planning period
					dateList = Karm.TaskObject.getWorkDoneDates(taskList[i])
				end		-- if type == "NORMAL" then ends
				if dateList then
					Karm.TaskObject.togglePlanningType(taskList[i],oTree.Planning)
					taskList[i].Planning.Period = {[0]="Period",count=0}
					for j=1,#dateList do
						taskList[i].Planning.Period[j] = {[0]="DP",Date=dateList[j]}
						taskList[i].Planning.Period.count = taskList[i].Planning.Period.count + 1
					end
				end
			end		-- if not found then ends
			if oTree.Nodes[taskList[i].TaskID]:MakeVisible() then
				dispGantt(taskTree,oTree.Nodes[taskList[i].TaskID].Row,false,oTree.Nodes[taskList[i].TaskID])
			end
		end		-- for i = 1,#taskList do ends
	end		-- local function enablePlanningMode(taskTree, taskList, type)ends
	
	function taskTreeINT.getPlanningTasks(taskTree)
		local oTree = taskTreeINT[taskTree]
		if not oTree.Planning then
			return nil
		else
			return oTree.taskList
		end
	end
	
	function taskTreeINT.getSelectedTask(taskTree)
		local oTree = taskTreeINT[taskTree]
		return oTree.Selected
	end
	
	function Karm.GUI.newTreeGantt(parent,noTaskTree)
		local taskTree = {}	-- Main object
		-- Main table to store the task tree that is on display
		taskTreeINT[taskTree] = {Nodes = {}, Roots = {}, update = true, nodeCount = 0, actionQ = {}, Planning = nil, taskList = nil, Selected = {},ShowActual = nil}
		-- A task in Nodes or Roots will have the following attributes:
		-- Expanded = if has children then true means it is expanded in the GUI
		-- MakeVisible = Function to make sure the task is visible
		-- Task = Contains the task data structure to the task
		-- Children = Contains the number of children on the tree for this node
		-- FirstChild = Contains the first child node
		-- LastChild = Contains the last child node
		-- Selected = Whether this node is selected. Allows multiple selections
		-- Title = Same as the task title unless there is no associated task
		-- Key = Same as TaskID unless no associated task
		-- ForeColor = Text color of the node
		-- BackColor = Background color of the node
		-- Prev = Previous Sibling
		-- Next = Next Sibling
		-- Parent = Parent
		-- Row = Row of the task in the task Grid (nil if task is not visible)
		-- taskTreeObj = main task tree GUI object to which this node belongs to
		-- Planning = Contains the planning mode schedule for the task if the task schedule planning is going on.
		
		-- Set task Tree internal as the metatable for exposed task tree empty table so we can catch all accesses to the task tree table and take actions appropriately
		setmetatable(taskTree, taskTreeINT)
		-- Metatable to access taskTreeINT for any missing keys
		setmetatable(taskTreeINT[taskTree],{__index=taskTreeINT})

		local oTree = taskTreeINT[taskTree]
		local ID = Karm.NewID()
		oTree.horSplitWin = wx.wxSplitterWindow(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxSP_3D, "Task Splitter")
		IDMap[ID] = taskTree
		-- wx.wxSize(Karm.GUI.initFrameW, 0.7*Karm.GUI.initFrameH)
		if not noTaskTree then
			oTree.horSplitWin:SetMinimumPaneSize(10)
		end

		ID = Karm.NewID()		
		oTree.treeGrid = wx.wxGrid(oTree.horSplitWin, ID, wx.wxDefaultPosition, 
						wx.wxDefaultSize, 0, "Task Tree Grid")
		IDMap[ID] = taskTree
	    oTree.treeGrid:CreateGrid(1,2)
	    oTree.treeGrid:SetColFormatBool(0)
	    oTree.treeGrid:SetRowLabelSize(15)
	    oTree.treeGrid:SetColLabelValue(0," ")
	    oTree.treeGrid:SetColLabelValue(1,"Tasks")
	    --Karm.GUI.treeGrid:SetCellHighlightPenWidth(0)
	    oTree.treeGrid:EnableGridLines(false)
	
		ID = Karm.NewID()
		oTree.ganttGrid = wx.wxGrid(oTree.horSplitWin, ID, wx.wxDefaultPosition, 
							wx.wxDefaultSize, 0, "Gantt Chart Grid")
		IDMap[ID] = taskTree
	    oTree.ganttGrid:CreateGrid(1,1)
	    oTree.ganttGrid:EnableGridLines(false)
	    -- Karm.GUI.ganttGrid:SetRowLabelSize(0)
	
		oTree.horSplitWin:SplitVertically(oTree.treeGrid, oTree.ganttGrid)
		if not noTaskTree then
			oTree.horSplitWin:SetSashPosition(0.3*parent:GetSize():GetWidth())
		else
			oTree.horSplitWin:Unsplit(oTree.treeGrid)
		end

		-- **************************EVENTS*******************************************
		-- SYNC THE SCROLLING OF THE TWO GRIDS	
		-- Create the scroll event to sync the 2 scroll bars in the wxScrolledWindow
		local f = onScrollTree(taskTree)
		--local f = onScTree
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, f)
	
		f = onScrollGantt(taskTree)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, f)
		
		-- Row Resize event
		f = onRowResizeTree(taskTree)
		oTree.treeGrid:Connect(wx.wxEVT_GRID_ROW_SIZE,f)
		f = onRowResizeGantt(taskTree)
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_ROW_SIZE,f)
		
		-- The TreeGrid label click event
		oTree.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,labelClick)
		--Karm.GUI.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,Karm.GUI.taskDblClick)
		
		-- The GanttGrid label click event
		oTree.ganttGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,ganttLabelClick)

		-- Gantt Grid Cell left click event
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,ganttCellClick)
		
		-- Gantt Cell double click event
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_DCLICK,ganttCellDblClick)
		
		-- TreeGrid left click on cell event
		oTree.treeGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,cellClick)
		
		-- Sash position changing event
		oTree.horSplitWin:Connect(wx.wxEVT_COMMAND_SPLITTER_SASH_POS_CHANGED, horSashAdjust)

		-- Splitter resize event
		oTree.horSplitWin:Connect(wx.wxEVT_SIZE, widgetResize)
	
		return taskTree
	end
	
	function nodeMeta.MakeVisible(node)
		local currNode = node
		if not nodeMeta[currNode] then
			return nil
		end
		while nodeMeta[currNode].Parent and not nodeMeta[currNode].Row do
			currNode = nodeMeta[currNode].Parent
			currNode.Expanded = true
		end
		return true
	end
	
	function nodeMeta.__index(tab,key)
		-- function to catch all accesses to a node object
		if key == "MakeVisible" then
			return nodeMeta.MakeVisible
		elseif key == "ID" then
			return nodeMeta	-- To identify node objects
		else
			return nodeMeta[tab][key]
		end
	end
	
	function nodeMeta.__newindex(tab,key,val)
		-- function to catch all setting commands to taskTree nodes
		
		-- define object references to bypass metamethod calls
		local oTree = taskTreeINT[nodeMeta[tab].taskTreeObj]
		local oNode = nodeMeta[tab]
		
		if key == "Expanded" then
			if oNode.Expanded and not val then
				-- Check if updates are enabled
				if oTree.update then
					if oNode.Row then
						-- Task is visible on the GUI
						-- Collapse this node in the GUI here
						local nextNode = nil
						local rows
						local currNode
						if oNode.Next then
							-- Number of rows to collapse
							rows = oNode.Next.Row - oNode.Row - 1
							-- Decrement the rows of subsequent tasks
							nextNode = oNode.Next
							while nextNode do
								nextNode.Row = nextNode.Row - rows 
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
							end
							nextNode = oNode.Next
						else
							-- Since there is no sibling the row collapsing will affect the ancestor which has siblings
							-- Find that ancestor:
							currNode = oNode.Parent
							while currNode and (not currNode.Next) do
								currNode = currNode.Parent
							end
							if currNode then
								nextNode = currNode.Next
								rows = nextNode.Row - oNode.Row - 1
								-- Decrement the rows of subsequent tasks
								while nextNode do
									nextNode.Row = nextNode.Row - rows 
									nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
								end
								nextNode = currNode.Next
							else
								rows = oTree.treeGrid:GetNumberRows() - oNode.Row
							end
						end
						-- Make nil the Row index of all children in the hierarchy of tab
						currNode = oTree.Nodes[taskTreeINT.nextNode(oNode.taskTreeObj,oNode.Key)]
						while currNode ~= nextNode do
							currNode.Row = nil
							currNode = oTree.Nodes[taskTreeINT.nextNode(currNode.taskTreeObj,currNode.Key)]
						end
						-- Adjust the row labels
						if nextNode then
							for i = nextNode.Row+rows,oTree.treeGrid:GetNumberRows() do
								oTree.treeGrid:SetRowLabelValue(i-rows-1,oTree.treeGrid:GetRowLabelValue(i-1))
								oTree.ganttGrid:SetRowLabelValue(i-rows-1,oTree.ganttGrid:GetRowLabelValue(i-1))
							end		
						end			
						-- Now delete all the rows
						oTree.treeGrid:DeleteRows(oNode.Row,rows)
						oTree.ganttGrid:DeleteRows(oNode.Row,rows)
						oTree.treeGrid:SetRowLabelValue(oNode.Row-1,"+")
						if #oTree.Selected > 0 then
							local i = 0
							while i < #oTree.Selected do
								i = i + 1
								if not oTree.Selected[i].Row then
									-- The selected node is not visible anymore
									for j = i + 1,#oTree.Selected do
										oTree.Selected[j-1] = oTree.Selected[j]
									end
									oTree.Selected[#oTree.Selected] = nil
								end
							end
							if #oTree.Selected == 0 then
								oTree.Selected[1] = tab
								oTree.Selected.Latest = 1
								tab.Selected = true
								if oTree.cellClickCallBack then
									oTree.cellClickCallBack(oNode.Task)
								end
							end
						end
					end
					-- Expanded was true and now making it false
					oNode.Expanded = nil
				else
					oTree.actionQ[#oTree.actionQ + 1] = "taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Expanded = nil"
				end		-- if oTree.update then ends
			elseif not oNode.Expanded and val then
				-- Check if updates are enabled
				if oTree.update then
					if oNode.Row and oNode.Children > 0 then
						-- Task is visible on the GUI
						-- Expand the node in the GUI here
						-- Number of rows to insert
						local rows = oNode.Children
						-- Increment the rows of subsequent tasks
						local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(oNode.taskTreeObj,oNode.Key)]
						while nextNode do
							nextNode.Row = nextNode.Row + rows 
							nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
						end
						-- Now insert the child rows here
						-- Find the hierarchy level
						local hierLevel = -1
						nextNode = oNode.FirstChild
						while nextNode do
							hierLevel = hierLevel + 1
							nextNode = nextNode.Parent
						end			
						nextNode = oNode.FirstChild
						local currRow = oNode.Row
						while nextNode do
							currRow = currRow + 1
							nextNode.Row = currRow
							dispTask(oNode.taskTreeObj,nextNode.Row,true,nextNode,hierLevel)
							dispGantt(oNode.taskTreeObj,nextNode.Row,true,nextNode)
							nextNode = nextNode.Next
						end
						oTree.treeGrid:SetRowLabelValue(oNode.Row-1,"-")
						-- Expanded was false and now making it true
						oNode.Expanded = true
						-- Now check if any of the exposed children have expanded true
						nextNode = oNode.FirstChild
						local toExpand = {}
						while nextNode do
							if nextNode.Expanded then
								nodeMeta[nextNode].Expanded = nil
								toExpand[#toExpand + 1] = nextNode
							end
							nextNode = nextNode.Next
						end
						-- Perform expansion of child nodes if any
						for i = 1,#toExpand do
							toExpand[i].Expanded = true
						end
					else
						-- Expanded was false and now making it true
						oNode.Expanded = true
					end
				else
					oTree.actionQ[#oTree.actionQ + 1] = "taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Expanded = true"
				end		-- if oTree.update then ends
			end		-- if oNode.Expanded and not val then ends
		elseif key == "Selected" then
			if oNode.Selected and not val then
				-- Selected was true and now making it false
				oNode.Selected = nil
				-- Unselect this node in the GUI
				oTree.Selected = {}
				oTree.treeGrid:SetGridCursor(0,0)
			elseif not oNode.Selected and val then
				-- Selected was false and now making it true
				oNode.Selected = true
				-- Select the node in the GUI here
				oTree.Selected = {oNode,Latest = 1}
				oTree.treeGrid:SetGridCursor(oNode.Row-1,1)
			end	
		elseif key == "ForeColor" or key == "BackColor" then
			if type(val) == "table" and val.Red and type(val.Red) == "number" and val.Green and type(val.Green) == "number" and
			  val.Blue and type(val.Blue) == "number" then
				if oTree.update then
					oNode[key] = val
					if oNode.Row then
						-- Calculate the hierLevel
						local hierLevel = 0
						local currNode = tab
						while nodeMeta[currNode].Parent do
							hierLevel = hierLevel + 1
							currNode = nodeMeta[currNode].Parent
						end
	
						dispTask(nodeMeta[tab].taskTreeObj,nodeMeta[tab].Row,false,tab,hierLevel)
					end
				else
					oTree.actionQ[#oTree.actionQ + 1] = "nodeMeta[taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."]]."..key.."={Red="..val.Red..",Green="..val.Green..",Blue="..val.Blue.."}"
					oTree.actionQ[#oTree.actionQ + 1] = "if ".."taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Row then local hierLevel = 0 local currNode = ".."taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."] while nodeMeta[currNode].Parent do hierLevel = hierLevel + 1 currNode = nodeMeta[currNode].Parent end dispTask(tab,nodeMeta[taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."]].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."],hierLevel) end"
				end		-- if oTree.update then ends
			end					
		else
			oNode[key] = val
		end		-- if key == ?? ends here
	end		-- function nodeMeta.__newindex(tab,key,val) ends

	function taskTreeINT.__index(tab,key)
		-- function to catch all accesses to taskTree
		return taskTreeINT[tab][key]
	end
	
	function taskTreeINT.__newindex(tab,key,val)
		-- function to catch all setting commands to Karm.GUI.taskTree
		-- object reference to bypass metamethod
		local oTree = taskTreeINT[tab]
		if key == "update" then
			if oTree.update and not val then
				-- Update was true and now making it false
				oTree.update = false
			elseif not oTree.update and val then
				oTree.update = true
				-- Now do the actionQ
				local env = getfenv()
				-- Write the up Values
				env.taskTreeINT = taskTreeINT
				env.tab = tab
				env.nodeMeta = nodeMeta
				env.dispTask = dispTask
				env.dispGantt = dispGantt
				--print(taskTreeINT)
				for i = 1,#oTree.actionQ do
					local f = loadstring(oTree.actionQ[i])
					setfenv(f,env)
					f()
				end
				-- Clear all pending actions
				oTree.actionQ = {}
			end
		elseif key == "Planning" then
			-- do nothing user cannot modify this
		elseif key == "taskList" then
			-- do nothing user cannot modify this
		elseif key == "Selected" then
			-- do nothing user cannot modify this
		elseif key == "UpdateKeys" then
			-- do nothing user cannot modify this
		elseif key == "SwapUpdateKeys" then
			-- do nothing user cannot modify this
		else
			oTree[key] = val
		end
	end
	
	function taskTreeINT.Clear(tab)
		taskTreeINT[tab].Nodes = {}
		taskTreeINT[tab].nodeCount = 0
		taskTreeINT[tab].Roots = {}
		taskTreeINT[tab].actionQ = {}
		taskTreeINT[tab].treeGrid:DeleteRows(0,taskTreeINT[tab].treeGrid:GetNumberRows())
		taskTreeINT[tab].ganttGrid:DeleteRows(0,taskTreeINT[tab].ganttGrid:GetNumberRows())
	end
		
	local function refreshGanttFunc(taskTree)
		-- Erase the previous data
		taskTreeINT[taskTree].ganttGrid:DeleteRows(0,taskTreeINT[taskTree].ganttGrid:GetNumberRows())
		local rowPtr = 0
		local hierLevel = 0
		for i,v in taskTreeINT.tvpairs(taskTree) do
			dispGantt(taskTree,rowPtr+1,true,v)
			rowPtr = rowPtr + 1
		end		-- Looping through all the nodes ends	
	end
	
	refreshGantt = refreshGanttFunc
	
	-- row begins with 1 as the 1st row of the spreadsheet
	local function dispTaskFunc(taskTree,row, createRow, taskNode, hierLevel)
		if (createRow and taskTreeINT[taskTree].treeGrid:GetNumberRows()<row-1) then
			return nil
		end
		if not createRow and taskTreeINT[taskTree].treeGrid:GetNumberRows()<row then
			return nil
		end
		if createRow then
			taskTreeINT[taskTree].treeGrid:InsertRows(row-1)
			-- Now shift the row labels
			for i = taskTreeINT[taskTree].treeGrid:GetNumberRows()-1,row,-1 do
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(i,taskTreeINT[taskTree].treeGrid:GetRowLabelValue(i-1))
			end
		end
		taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,1,string.rep(" ",hierLevel*4)..taskNode.Title)
		taskTreeINT[taskTree].treeGrid:SetCellAlignment(row-1,1,wx.wxALIGN_LEFT, wx.wxALIGN_CENTRE)
		if taskNode.Children > 0 then
			if taskNode.Expanded then
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1,"-")
			else
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1,"+")
			end
		else
			taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1," ")
		end
		if taskNode.Task and taskNode.Task.Status and string.upper(taskNode.Task.Status) == "DONE" then
			taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,0,"1")
		else
			taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,0,"0")
		end
		taskTreeINT[taskTree].treeGrid:SetReadOnly(row-1,0)
		taskTreeINT[taskTree].treeGrid:SetReadOnly(row-1,1)
		-- Set the back ground color
		if taskNode.BackColor then
			taskTreeINT[taskTree].treeGrid:SetCellBackgroundColour(row-1,1,wx.wxColour(taskNode.BackColor.Red,taskNode.BackColor.Green,taskNode.BackColor.Blue))
		end
		if taskNode.ForeColor then
			taskTreeINT[taskTree].treeGrid:SetCellTextColour(row-1,1,wx.wxColour(taskNode.ForeColor.Red,taskNode.ForeColor.Green,taskNode.ForeColor.Blue))
		end
		taskTreeINT[taskTree].treeGrid:ForceRefresh()
	end
	
	dispTask = dispTaskFunc
	
	-- row begins with 1 as the 1st row of the spreadsheet
	local function dispGanttFunc(taskTree,row,createRow,taskNode)
		if (createRow and taskTreeINT[taskTree].ganttGrid:GetNumberRows()<row-1) then
			return nil
		end
		if not createRow and taskTreeINT[taskTree].ganttGrid:GetNumberRows()<row then
			return nil
		end
		if createRow then
			taskTreeINT[taskTree].ganttGrid:InsertRows(row-1)
			-- Now shift the row labels
			for i = taskTreeINT[taskTree].ganttGrid:GetNumberRows(),row,-1 do
				taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(i,taskTreeINT[taskTree].ganttGrid:GetRowLabelValue(i-1))
			end
		end
		-- Now update the ganttGrid to include the schedule
		local startDay = Karm.Utility.toXMLDate(taskTreeINT[taskTree].startDate:Format("%m/%d/%Y"))
		local finDay = Karm.Utility.toXMLDate(taskTreeINT[taskTree].finDate:Format("%m/%d/%Y"))
		local days = taskTreeINT[taskTree].ganttGrid:GetNumberCols()
		--print(Karm.Utility.getWeekDay(startDay))
		if not taskNode.Task then
			-- No task associated with the node so color the cells to show no schedule
			taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"X")
			local currDate = Karm.Utility.XMLDate2wxDateTime(startDay)
			for i = 1,days do
				--print(currDate:Format("%m/%d/%Y"),Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))))
				if Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
					local newColor = {Red=Karm.GUI.noScheduleColor.Red - Karm.GUI.sunDayOffset.Red,Green=Karm.GUI.noScheduleColor.Green - Karm.GUI.sunDayOffset.Green,
					Blue=Karm.GUI.noScheduleColor.Blue-Karm.GUI.sunDayOffset.Blue}
					if newColor.Red < 0 then newColor.Red = 0 end
					if newColor.Green < 0 then newColor.Green = 0 end
					if newColor.Blue < 0 then newColor.Blue = 0 end
					taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
				else
					taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(Karm.GUI.noScheduleColor.Red,
						Karm.GUI.noScheduleColor.Green,Karm.GUI.noScheduleColor.Blue))
				end
				taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
				currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
				taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
			end
		else
			-- Task exists so create the schedule
			--Get the datelist
			-- Check if planning mode for this task
			local planning = nil
			if taskTreeINT[taskTree].Planning then
				for i = 1,#taskTreeINT[taskTree].taskList do
					if taskTreeINT[taskTree].taskList[i] == taskNode.Task then
						-- This is a planning mode task
						planning = true
						break
					end
				end
			end
			local dateList
			if taskTreeINT[taskTree].ShowActual then
				dateList = Karm.TaskObject.getWorkDates(taskNode.Task,taskTreeINT[taskTree].Bubble)
			else
				dateList = Karm.TaskObject.getDates(taskNode.Task,taskTreeINT[taskTree].Bubble, planning)
			end
			if not dateList then
				-- No task associated with the node or no schedule so color the cells to show no schedule
				if planning then
					taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"(P)X")
				else
					taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"X")
				end
				local currDate = Karm.Utility.XMLDate2wxDateTime(startDay)
				for i = 1,days do
					if Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
						local newColor = {Red=Karm.GUI.noScheduleColor.Red - Karm.GUI.sunDayOffset.Red,Green=Karm.GUI.noScheduleColor.Green - Karm.GUI.sunDayOffset.Green,
						Blue=Karm.GUI.noScheduleColor.Blue-Karm.GUI.sunDayOffset.Blue}
						if newColor.Red < 0 then newColor.Red = 0 end
						if newColor.Green < 0 then newColor.Green = 0 end
						if newColor.Blue < 0 then newColor.Blue = 0 end
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
					else
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(Karm.GUI.noScheduleColor.Red,
							Karm.GUI.noScheduleColor.Green,Karm.GUI.noScheduleColor.Blue))
					end
					taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
					currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
					taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
				end
			else
				-- Some dates are scheduled for the task
				local map
				if planning then
					map = {Estimate="(P)E",Commit = "(P)C", Revs = "(P)R", Actual = "(P)A"}
				else
					map = {Estimate="E",Commit = "C", Revs = "R", Actual = "A"}
				end
				-- Erase the previous schedule on the row
				local currDate = Karm.Utility.XMLDate2wxDateTime(startDay)
				for i=1,days do
					if Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
						local newColor = {Red=Karm.GUI.emptyDayColor.Red - Karm.GUI.sunDayOffset.Red,Green=Karm.GUI.emptyDayColor.Green - Karm.GUI.sunDayOffset.Green,
						Blue=Karm.GUI.emptyDayColor.Blue-Karm.GUI.sunDayOffset.Blue}
						if newColor.Red < 0 then newColor.Red = 0 end
						if newColor.Green < 0 then newColor.Green = 0 end
						if newColor.Blue < 0 then newColor.Blue = 0 end
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
					else
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(Karm.GUI.emptyDayColor.Red,
							Karm.GUI.emptyDayColor.Green,Karm.GUI.emptyDayColor.Blue))
					end
					taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
					currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
					taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
				end		
				local before,after
				for i=1,#dateList do
					currDate = Karm.Utility.XMLDate2wxDateTime(dateList[i].Date)
					if dateList[i].Date>=startDay and dateList[i].Date<=finDay then
						-- This date is in range find the column which needs to be highlighted
						local col = 0					
						local stepDate = Karm.Utility.XMLDate2wxDateTime(startDay)
						while not stepDate:IsSameDate(currDate) do
							stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
							col = col + 1
						end
						--taskTreeINT[taskTree].startDate:Subtract(wx.wxDateSpan(0,0,0,col))
						if Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
							local newColor = {Red=dateList[i].BackColor.Red - Karm.GUI.sunDayOffset.Red,
							  Green=dateList[i].BackColor.Green - Karm.GUI.sunDayOffset.Green,
							  Blue=dateList[i].BackColor.Blue-Karm.GUI.sunDayOffset.Blue}
							if newColor.Red < 0 then newColor.Red = 0 end
							if newColor.Green < 0 then newColor.Green = 0 end
							if newColor.Blue < 0 then newColor.Blue = 0 end
							taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
						else
							taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(dateList[i].BackColor.Red,
								dateList[i].BackColor.Green,dateList[i].BackColor.Blue))
						end
						taskTreeINT[taskTree].ganttGrid:SetCellTextColour(row-1,col,wx.wxColour(dateList[i].ForeColor.Red,dateList[i].ForeColor.Green,dateList[i].ForeColor.Blue))
						taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,col,dateList[i].Text)
						taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,col)
					else
						if dateList[i].Date<startDay then
							before = true
						end
						if dateList[i].Date>finDay then
							after = true
						end
					end		-- if dateList[i]>=startDay and dateList[i]<=finDay then ends
				end		-- for i=1,#dateList do ends
				local str = ""
				if before then
					str = "<"
				end
				if after then
					str = str..">"
				end
				taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,map[dateList.typeSchedule]..tostring(dateList.index)..str)
			end		-- if not dateList then ends
		end	
		taskTreeINT[taskTree].ganttGrid:ForceRefresh()
	end		-- local function dispGanttFunc(taskTree,row,createRow,taskNode) ends
	
	dispGantt = dispGanttFunc
	
	-- Updates the keys of a node from the underlying tasks
	function taskTreeINT.UpdateKeys(taskTree,node,noRecurse)
		if node.ID ~= nodeMeta then
			error("Need valid node objects to UpdateKeys.",2)
		end
		if not nodeMeta[node].Task then
			error("Need a node with an associated task to update the key.",2)
		end
		local currNode = node
		local oTree = taskTreeINT[taskTree]
		oTree.Nodes[nodeMeta[currNode].Key]  = nil
		nodeMeta[currNode].Key = nodeMeta[currNode].Task.TaskID
		oTree.Nodes[nodeMeta[currNode].Key] = currNode
		if noRecurse then
			return
		end
		if nodeMeta[currNode].FirstChild then
			currNode = nodeMeta[currNode].FirstChild
			while currNode ~= node do
				oTree.Nodes[nodeMeta[currNode].Key]  = nil
				nodeMeta[currNode].Key = nodeMeta[currNode].Task.TaskID
				oTree.Nodes[nodeMeta[currNode].Key] = currNode
				if nodeMeta[currNode].FirstChild then
					currNode = nodeMeta[currNode].FirstChild
				elseif nodeMeta[currNode].Next then
					currNode = nodeMeta[currNode].Next
				else
					while currNode ~= node and not nodeMeta[currNode].Next do
						currNode = nodeMeta[currNode].Parent
					end
					if currNode == node then 
						break
					end
				end		-- if nodeMeta[currNode].FirstChild then ends here
			end		-- while currNode ~= node do ends
		end		-- if nodeMeta[currNode].FirstChild then ends		
	end
	
	-- Function to swap the keys of the given 2 node hierarchies. They keys are still taken from the taskIDs for task swap
	-- The function just assumes that there would eb key swapping happenning so uses a 3rd storage element to make the swap
	-- happen and make data consistent in the Nodes table (Where each node is accessible from its key)
	function taskTreeINT.SwapUpdateKeys(taskTree,node1,node2)
		if getmetatable(node1)~=nodeMeta or getmetatable(node2)~=nodeMeta then
			error("Need valid node objects to SwapKeys.",2)
		end
		if (not nodeMeta[node1].Task and nodeMeta[node2].Task) or (not nodeMeta[node2].Task and nodeMeta[node1].Task) then
			error("Cannot Swap Keys between a Spore and task.",2)
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if these are spore nodes
		if nodeMeta[node1].Key:sub(1,#Karm.Globals.ROOTKEY)==Karm.Globals.ROOTKEY then
			-- ################################################################################
			-- QUESTIONALBLE SINCE SPORE KEYS ARE BASED ON THEIR FILE NAMES!
			-- ################################################################################
			-- These are spores
			-- Just swap the spore keys
			nodeMeta[node1].Key, nodeMeta[node2].Key = nodeMeta[node2].Key, nodeMeta[node1].Key
			oTree.Nodes[nodeMeta[node1].Key] = node1
			oTree.Nodes[nodeMeta[node2].Key] = node2
		else
			-- Move the node1 hierarchy out of Nodes table
			local node1Hier = {}
			local currNode = node1
			node1Hier[nodeMeta[node1].Key] = node1
			oTree.Nodes[nodeMeta[node1].Key]  = nil
			if nodeMeta[currNode].FirstChild then
				currNode = nodeMeta[currNode].FirstChild
				while currNode ~= node1 do
					node1Hier[nodeMeta[currNode].Key] = currNode
					oTree.Nodes[nodeMeta[currNode].Key]  = nil
					if nodeMeta[currNode].FirstChild then
						currNode = nodeMeta[currNode].FirstChild
					elseif nodeMeta[currNode].Next then
						currNode = nodeMeta[currNode].Next
					else
						while currNode ~= node1 and not nodeMeta[currNode].Next do
							currNode = nodeMeta[currNode].Parent
						end
						if currNode == node1 then 
							break
						end
					end		-- if nodeMeta[currNode].FirstChild then ends here
				end		-- while currNode ~= node1 do ends
			end		-- if nodeMeta[currNode].FirstChild then ends
			-- Now convert node2 hierarchy to the proper Keys
			taskTreeINT.UpdateKeys(taskTree,node2)
			-- Now add the node1 nodes back with the correct keys
			for k,v in pairs(node1Hier) do
				nodeMeta[v].Key = nodeMeta[v].Task.TaskID
				oTree.Nodes[nodeMeta[v].Key] = v
			end
		end		-- if not nodeMeta[node1].Task then ends
	end

	-- Refreshes a node with the key same as the given task's TaskID
	-- This is a total refresh of the task name and also the schedule
	function taskTreeINT.RefreshNode(taskTree,task)
		return taskTreeINT.UpdateNode(taskTree,task)
	end
	
	function taskTreeINT.UpdateNode(taskTree,task)
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[task.TaskID]
		
		nodeMeta[node].Task = task
		nodeMeta[node].Title = task.Title
		
		if nodeMeta[node].Row then
			-- Calculate the hierLevel
			local hierLevel = 0
			local currNode = node
			while nodeMeta[currNode].Parent do
				hierLevel = hierLevel + 1
				currNode = nodeMeta[currNode].Parent
			end
	
			if oTree.update then
				dispTask(taskTree,nodeMeta[node].Row,false,node,hierLevel)
				dispGantt(taskTree,nodeMeta[node].Row,false,node)
				if #oTree.Selected > 0 then
					oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
				end
			else
				-- Add to actionQ
				oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
					string.format("%q",task.TaskID).."].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",task.TaskID).."],"..tostring(hierLevel)..")"
				oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes["..
					string.format("%q",task.TaskID).."].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",task.TaskID).."])"				
				oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
			end
		end		-- if nodeMeta[node].Row then ends
	end
	
	function taskTreeINT.DeleteTree(taskTree,Key)
		if Key == Karm.Globals.ROOTKEY then
			error("DeleteTree: Function cannot be used to delete a Root node,",2)
		end
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[Key]
		local parent = nodeMeta[node].Parent
		if not node then
			-- Already deleted
			return
		end
		local nodesToDel = {node}
		local rowsToDel = {nodeMeta[node].Row}
		-- Make list of nodes and rows to delete
		local k, nextNode = taskTree:nextNode(Key)
		while nextNode do
			-- Check if this is in the child hierarchy for node
			local inHier = nil
			local currNode = nextNode
			while currNode and not inHier do
				if nodeMeta[currNode].Parent == node then
					-- In the child hierarchy
					inHier = true
				end
				currNode = nodeMeta[currNode].Parent
			end
			if not inHier then
				break	-- once a hierarchy is exited there cannot be another following node in the hierarchy
			end
			-- Add to the delete list
			nodesToDel[#nodesToDel + 1] = nextNode
			rowsToDel[#rowsToDel + 1] = nodeMeta[nextNode].Row
			k, nextNode = taskTree:nextNode(k)
		end		-- while nextNode do ends
		-- Update the links
		if nodeMeta[node].Prev then
			nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
		end
		if nodeMeta[node].Next then
			nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
		end
		-- Parent links
		nodeMeta[parent].Children = nodeMeta[parent].Children - 1
		if not nodeMeta[node].Prev then
			-- This was the first child
			nodeMeta[parent].FirstChild = nodeMeta[node].Next
		end
		if not nodeMeta[node].Next then
			-- This was the last child
			nodeMeta[parent].LastChild = nodeMeta[node].Prev
		end
		
		if nextNode then
			-- Adjust the row labels
			if not nodeMeta[nextNode].Row then
				k,nextNode = taskTree:nextVisibleNode(k)
			end
			local nextStartNode = nextNode
			while nextNode do
				oTree.treeGrid:SetRowLabelValue(nodeMeta[nextNode].Row-#rowsToDel-1,oTree.treeGrid:GetRowLabelValue(nodeMeta[nextNode].Row-1))
				oTree.ganttGrid:SetRowLabelValue(nodeMeta[nextNode].Row-#rowsToDel-1,oTree.ganttGrid:GetRowLabelValue(nodeMeta[nextNode].Row-1))
				-- Update the node Row
				nodeMeta[nextNode].Row = nodeMeta[nextNode].Row-#rowsToDel
				k,nextNode = taskTree:nextVisibleNode(k)
			end
		end	
		-- Update the parent row label
		if nodeMeta[parent].Children == 0 then
			oTree.treeGrid:SetRowLabelValue(nodeMeta[nodeMeta[node].Parent].Row-1,"")
			nodeMeta[parent].Expanded = false
		end
		-- Now delete everything
		-- Delete the nodes
		for i = 1,#nodesToDel do
			oTree.Nodes[nodeMeta[nodesToDel[i]].Key] = nil
			nodeMeta[nodesToDel[i]] = nil
		end
		oTree.nodeCount = oTree.nodeCount - #nodesToDel
		
		-- Delete the rows
		for i = 1,#rowsToDel do
			oTree.treeGrid:DeleteRows(rowsToDel[i]-1)
			oTree.ganttGrid:DeleteRows(rowsToDel[i]-1)
			-- Adjust the row numbers to account for deleted row	
			for j = i + 1,#rowsToDel do	
				if rowsToDel[j] > rowsToDel[i] then
					rowsToDel[j] = rowsToDel[j] - 1
				end
			end
		end
		
		-- Remove the nodes from the Selected list
		if #oTree.Selected > 0 then
			local i = 1
			while i <= #oTree.Selected do
				for j = 1,#nodesToDel do
					if oTree.Selected[i] == nodesToDel[j] then
						for k = i+1,#oTree.Selected-1 do
							oTree.Selected[k-1] = oTree.Selected[k]
						end
						oTree.Selected[#oTree.Selected] = nil
						break
					end
				end
				i = i + 1
			end
			if #oTree.Selected == 0 then
				oTree.Selected[1] = parent
				oTree.Selected.Latest = 1
				parent.Selected = true
				if oTree.cellClickCallBack then
					oTree.cellClickCallBack(parent.Task)
				end
			else
				if oTree.Selected.Latest > #oTree.Selected then
					oTree.Selected.Lates = #oTree.Selected
				end
			end
		end
	end		-- function taskTreeINT.DeleteTree(taskTree,Key) ends
	
	function taskTreeINT.DeleteSubUpdate(taskTree,Key)
		if Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			error("DeleteSubUpdate: Function cannot be used to delete a spore or Root node.",2)
		end
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[Key]
		local parent = nodeMeta[node].Parent
		-- Expand the node first
		node.Expanded = true
		-- Update the row numbers of all subsequent tasks first
		local key,nextNode = taskTree:nextVisibleNode(Key)
		local nextV = nextNode
		while nextNode do
			-- Check if this is in the child hierarchy for node
			local inHier = nil
			local currNode = nextNode
			while currNode and not inHier do
				if nodeMeta[currNode].Parent == node then
					-- In the child hierarchy
					inHier = true
				end
				currNode = nodeMeta[currNode].Parent
			end
			if inHier then
				-- Update the display of the task
				-- Calculate the hierLevel
				local hierLevel = -1
				local cN = nextNode
				while nodeMeta[cN].Parent do
					hierLevel = hierLevel + 1
					cN = nodeMeta[cN].Parent
				end
		
				if oTree.update then
					dispTask(taskTree,nodeMeta[nextNode].Row,false,nextNode,hierLevel)
					dispGantt(taskTree,nodeMeta[nextNode].Row,false,nextNode)
					if #oTree.Selected > 0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
						string.format("%q",nodeMeta[nextNode].Key).."'].Row,false,taskTreeINT[tab].Nodes['"..string.format("%q",nodeMeta[nextNode].Key).."'],"..tostring(hierLevel)..")"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes['"..
						string.format("%q",nodeMeta[nextNode].Key).."'].Row,false,taskTreeINT[tab].Nodes['"..string.format("%q",nodeMeta[nextNode].Key).."'])"				
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
				end
			end
			-- Update the row now since this will be the new row after the node row is deleted
			nodeMeta[nextNode].Row = nodeMeta[nextNode].Row - 1
			key, nextNode = taskTree:nextVisibleNode(key)
		end		-- while nextNode do ends
		
		-- Update the parent of all the immediate children and the hierLevel of all children hierarchy
		local currNode = nodeMeta[node].FirstChild
		while currNode do		
			-- Update the parent
			nodeMeta[currNode].Parent = parent
			currNode = nodeMeta[currNode].Next
		end

		-- Update the Parent links for the node
		nodeMeta[parent].Children = nodeMeta[parent].Children + nodeMeta[node].Children - 1
		if not nodeMeta[node].Prev then
			-- The FirstChild is changing
			if nodeMeta[node].FirstChild then
				nodeMeta[parent].FirstChild = nodeMeta[node].FirstChild
			else
				nodeMeta[parent].FirstChild = nodeMeta[node].Next
			end
		end
		if not nodeMeta[node].Next then
			-- The LastChild is changing
			if nodeMeta[node].LastChild then
				nodeMeta[parent].LastChild = nodeMeta[node].LastChild
			else
				nodeMeta[parent].LastChild = nodeMeta[node].Prev
			end
		end

		-- Update the sibling links of the node
		if nodeMeta[node].Prev then
			if nodeMeta[node].FirstChild then
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].FirstChild
				nodeMeta[nodeMeta[node].FirstChild].Prev = nodeMeta[node].Prev
			else
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
				if nodeMeta[node].Next then
					nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
				end
			end
		end
		if nodeMeta[node].Next then
			if nodeMeta[node].LastChild then
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].LastChild
				nodeMeta[nodeMeta[node].LastChild].Next = nodeMeta[node].Next
			else
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
				if nodeMeta[node].Prev then
					nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
				end
			end
		end


		-- Adjust the row labels
		for i = nodeMeta[node].Row+1,oTree.treeGrid:GetNumberRows() do
			oTree.treeGrid:SetRowLabelValue(i-2,oTree.treeGrid:GetRowLabelValue(i-1))
			oTree.ganttGrid:SetRowLabelValue(i-2,oTree.ganttGrid:GetRowLabelValue(i-1))
		end		
		-- Finally delete the node row
		oTree.treeGrid:DeleteRows(nodeMeta[node].Row-1)
		oTree.ganttGrid:DeleteRows(nodeMeta[node].Row-1)
		oTree.Nodes[nodeMeta[node].Key] = nil
		nodeMeta[node] = nil
		oTree.nodeCount = oTree.nodeCount - 1
		-- Update the - sign on the parent
		if not nodeMeta[parent].FirstChild then
			-- Nothing left under the parent
			oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"")
		elseif not nodeMeta[nodeMeta[parent].FirstChild].Row then
			oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"+")
			nodeMeta[parent].Expanded = nil
		end
		-- Remove the node from the Selected list
		if #oTree.Selected > 0 then
			local index
			for i = 1,#oTree.Selected do
				if oTree.Selected[i] == node then
					index = i
					break
				end
			end
			if index then
				for i = index+1,#oTree.Selected-1 do
					oTree.Selected[i-1] = oTree.Selected[i]
				end
				oTree.Selected[#oTree.Selected] = nil
				if #oTree.Selected == 0 then
					if not nextV then
						nextV = parent
					end
					oTree.Selected[1] = nextV
					oTree.Selected.Latest = 1
					nextV.Selected = true
					if oTree.cellClickCallBack then
						oTree.cellClickCallBack(nextV.Task)
					end
				else
					if oTree.Selected.Latest > #oTree.Selected then
						oTree.Selected.Latest = #oTree.Selected
					end
				end
			end
		end
	end		-- function taskTreeINT.DeleteSubUpdate(taskTree,task) ends
	
	function taskTreeINT.AddNode(taskTree,nodeInfo)
		-- Add the node to the GUI task tree
		-- nodeInfo.Relative = relative of this new node (should be a task ID) (Can be nil - together with relation means root node)
		-- nodeInfo.Relation = relation of this new node to the Relative. This can be "Child", "Next Sibling", "Prev Sibling" (Can be nil)
		-- nodeInfo.Key = key by which this node is uniquely identified in the tree
		-- nodeInfo.Text = text to be visible to represent the node in the GUI
		-- nodeInfo.Task = Task to be associated with this node (Can be nil)
		
		local oTree = taskTreeINT[taskTree]
		-- First make sure the key is unique
		if oTree.Nodes[nodeInfo.Key] then
			-- Key already exists
			wx.wxMessageBox("Trying to add a duplicate Key ("..nodeInfo.Key..") to the task Tree.",
		                wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
			return nil
		end
		-- Check if Relative exist
		if nodeInfo.Relative then
			if not oTree.Nodes[nodeInfo.Relative] then
				-- Relative specified but does not exist
				wx.wxMessageBox("Specified relative does not exist ("..nodeInfo.Relative..") in the task Tree.",
			                wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
				return nil
			end
			-- Since relative is specified relation should be specified
			if not nodeInfo.Relation then
				-- Relative specified but Relation not specified
				wx.wxMessageBox("No relation specified for task (".. nodeInfo.Text..").",
			                wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
				return nil
			end
		end
		-- Check if Relation if correct
		if nodeInfo.Relation then
			if string.upper(nodeInfo.Relation) ~= "CHILD" and string.upper(nodeInfo.Relation) ~= "NEXT SIBLING" and string.upper(nodeInfo.Relation) ~= "PREV SIBLING" then
				-- Relation specified incorrectly 
				wx.wxMessageBox("Specified relation is not correct ("..nodeInfo.Relation.."). Allowed values are 'Child', 'Next Sibling', 'Prev Sibling'.",
			                wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
				return nil
			end
		end
		
		-- Now add the node
		if not nodeInfo.Relative then
			-- This is a root node
			oTree.Roots[#oTree.Roots + 1] = {}
			nodeMeta[oTree.Roots[#oTree.Roots]] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children=0, taskTreeObj = taskTree}
			if oTree.Roots[#oTree.Roots - 1] then
				oTree.Roots[#oTree.Roots].Prev = oTree.Roots[#oTree.Roots - 1]
				oTree.Roots[#oTree.Roots - 1].Next = oTree.Roots[#oTree.Roots]
			end 
			-- Set the nodes meta table to control the node's interface
			setmetatable(oTree.Roots[#oTree.Roots],nodeMeta)
			oTree.Nodes[nodeInfo.Key] = oTree.Roots[#oTree.Roots]
			oTree.nodeCount = oTree.nodeCount + 1
			-- Add it to the GUI here
			if oTree.Nodes[nodeInfo.Key].Prev then
				oTree.Nodes[nodeInfo.Key].Row = oTree.Nodes[nodeInfo.Key].Prev.Row+1
				if oTree.update then
					dispTask(taskTree,oTree.Nodes[nodeInfo.Key].Row,true,oTree.Nodes[nodeInfo.Key],0)
					dispGantt(taskTree,oTree.Nodes[nodeInfo.Key].Row,true,oTree.Nodes[nodeInfo.Key])
					if #oTree.Selected > 0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],0)"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"				
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
				end
			else
				oTree.Nodes[nodeInfo.Key].Row = 1
				if oTree.update then
					dispTask(taskTree,1,true,oTree.Nodes[nodeInfo.Key],0)
					dispGantt(taskTree,1,true,oTree.Nodes[nodeInfo.Key])
					if #oTree.Selected>0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,1,true,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."],0)"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,1,true,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."])"
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
				end
			end

			-- return the node
			return oTree.Nodes[nodeInfo.Key]
		else
			-- Add it according to the relation 
			if string.upper(nodeInfo.Relation) == "CHILD" then
				-- Add child
				local parent = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = parent, taskTreeObj = taskTree}
				nodeMeta[parent].Children = nodeMeta[parent].Children + 1 -- increment number of children
				if nodeMeta[parent].FirstChild then
					-- Parent already has children
					nodeMeta[parent].LastChild.Next = newNode
					nodeMeta[newNode].Prev = nodeMeta[parent].LastChild
					nodeMeta[parent].LastChild = newNode
				else
					nodeMeta[parent].FirstChild = newNode
					nodeMeta[parent].LastChild = newNode
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if nodeMeta[parent].Expanded then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					-- Get the row number where this task needs to be placed
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[parent].Key)]
					while true do
						-- Check if nextNode is in the child hierarchy of parent
						local prevNode = parent
						local currNode = nextNode
						local inHier = nil
						while currNode do
							if nodeMeta[currNode].Parent == parent then
								-- In the child hierarchy
								prevNode = nextNode
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
								inHier = true
								break
							end
							currNode = nodeMeta[currNode].Parent
						end
						if not nextNode then
							-- This would be last node in the grid so assign the row one greater than the last visible node
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[prevNode].Row + 1
							break
						end
						if not inHier then
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nextNode].Row
							break
						end
					end
					-- Update the row values of subsequent tasks	
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end

					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
					end
				elseif nodeMeta[parent].Row and nodeMeta[parent].Children == 1 then
					-- This is the 1st child to this visible parent
					-- Add the row label to '+'
					oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"+")
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			elseif string.upper(nodeInfo.Relation) == "NEXT SIBLING" then
				-- Add next sibling
				local sib = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = nodeMeta[sib].Parent, taskTreeObj=taskTree}
				if nodeMeta[sib].Parent then
					nodeMeta[nodeMeta[sib].Parent].Children = nodeMeta[nodeMeta[sib].Parent].Children + 1 -- increment number of children
				else
					oTree.Roots[#oTree.Roots + 1] = newNode
				end
				if nodeMeta[sib].Next then
					-- Node needs to be inserted between these
					nodeMeta[nodeMeta[sib].Next].Prev = newNode
					nodeMeta[newNode].Next = nodeMeta[sib].Next
					nodeMeta[sib].Next = newNode
					nodeMeta[newNode].Prev = sib
				else
					-- Node is the last one
					nodeMeta[sib].Next = newNode
					nodeMeta[newNode].Prev = sib
					if nodeMeta[sib].Parent then
						nodeMeta[nodeMeta[sib].Parent].LastChild = newNode
					end
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if (nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent and 
					nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent].Expanded) or
					not nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					-- Get the row number where this task needs to be placed
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[sib].Key)]
					while true do
						-- Check if nextNode is in the child hierarchy of sib
						local prevNode = sib
						local currNode = nextNode
						local inHier = nil
						while currNode do
							if nodeMeta[currNode].Parent == sib then
								-- In the child hierarchy
								prevNode = nextNode
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
								inHier = true
								break
							end
							currNode = nodeMeta[currNode].Parent
						end
						if not nextNode then
							-- This would be last node in the grid so assign the row one greater than the last visible node
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[prevNode].Row + 1
							break
						end
						if not inHier then
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nextNode].Row
							break
						end
					end
					-- Update the row values of subsequent tasks	
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end
					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
					end
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			else 
				-- Add previous sibling
				local sib = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = nodeMeta[sib].Parent, taskTreeObj = taskTree}
				if nodeMeta[sib].Parent then
					nodeMeta[nodeMeta[sib].Parent].Children = nodeMeta[nodeMeta[sib].Parent].Children + 1 -- increment number of children
				else
					oTree.Roots[#oTree.Roots + 1] = newNode
				end
				if nodeMeta[sib].Prev then
					-- Node needs to be inserted between these
					nodeMeta[nodeMeta[sib].Prev].Next = newNode
					nodeMeta[newNode].Prev = nodeMeta[sib].Prev
					nodeMeta[sib].Prev = newNode
					nodeMeta[newNode].Next = sib
				else
					-- Node is the First one
					nodeMeta[sib].Prev = newNode
					nodeMeta[newNode].Next = sib
					if nodeMeta[sib].Parent then
						nodeMeta[nodeMeta[sib].Parent].FirstChild = newNode
					end
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if (nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent and 
					nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent].Expanded) or
					not nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Next].Row
					-- Update the row values of subsequent tasks	
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Key)]
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end
					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
					end
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			end
		end		-- if not nodeInfo.Relative then ends here
	end		-- function taskTreeINT.AddNode ends here
	
	local function labelClickFunc(event)
		-- Find the row of the click
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		if row>-1 then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			-- Check if the taskNode has children
			if nodeMeta[taskNode].Children > 0 then
				if nodeMeta[taskNode].Expanded then
					taskNode.Expanded = nil
				else
					taskNode.Expanded = true
				end
			end
		end		
		if taskTreeINT[obj].rowLabelClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].rowLabelClickCallBack(taskNode.Task, row, -1)
		end
		--event:Skip()
	end
	
	local function ganttLabelClickFunc(event)
		-- Find the row of the click
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		local col = event:GetCol()
		if taskTreeINT[obj].Planning then
			local oTree = taskTreeINT[obj]
			if row > -1 then
				for i = 1,#oTree.taskList do
					if oTree.Nodes[oTree.taskList[i].TaskID].Row == row+1 then
						-- This is the task modify/add the planning schedule
						Karm.TaskObject.togglePlanningType(oTree.taskList[i],oTree.Planning)
						dispGanttFunc(obj,row+1,false,oTree.Nodes[oTree.taskList[i].TaskID])
						break
					end
				end
			end		-- if row > -1 then ends
		end		-- if taskTreeINT[obj].Planning then ends
		if taskTreeINT[obj].ganttRowLabelClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].ganttRowLabelClickCallBack(taskNode.Task, row, -1)
		end
		--event:Skip()
	end

	local function onScrollTreeFunc(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			oTree.ganttGrid:Scroll(oTree.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.treeGrid:GetScrollPos(wx.wxVERTICAL))
			event:Skip()
		end
	end
	
--		 function onScTree(event)
--		 	oTree = event:GetEventObject()
--			--oTree = taskTreeINT[obj]
--			oTree.ganttGrid:Scroll(oTree.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.treeGrid:GetScrollPos(wx.wxVERTICAL))
--			event:Skip()
--		end
	local function onRowResizeGanttFunc(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			local row = event:GetRowOrCol()
			oTree.treeGrid:SetRowSize(row,oTree.ganttGrid:GetRowSize(row))
			oTree.treeGrid:ForceRefresh()
			event:Skip()
		end
	end
	
	onRowResizeGantt = onRowResizeGanttFunc
	
	local function onRowResizeTreeFunc(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			local row = event:GetRowOrCol()
			oTree.ganttGrid:SetRowSize(row,oTree.treeGrid:GetRowSize(row))
			oTree.ganttGrid:ForceRefresh()
			event:Skip()
		end	
	end
	
	onRowResizeTree = onRowResizeTreeFunc
	
	local function onScrollGanttFunc(obj)
		return function(event)
			event:Skip()
			local oTree = taskTreeINT[obj]
			oTree.treeGrid:Scroll(oTree.treeGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.ganttGrid:GetScrollPos(wx.wxVERTICAL))

			local currDate = oTree.startDate
			local finDate = oTree.finDate
			local count = 0
--			local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count))
--			y1 = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count+1),wx.wxGridCellCoords(0,count+1))
--   			Karm.GUI.frame:SetStatusText(tostring(y:GetTopLeft():GetX())..","..tostring(y:GetTopLeft():GetY())..","..
--   			  tostring(y1:GetTopLeft():GetX())..","..tostring(y1:GetTopLeft():GetY()), 1)
   			
    		local x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
    		--local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
    		local x = oTree.ganttGrid:IsVisible(0,count)
			--while x==0 and not currDate:IsLaterThan(finDate) do
			while not x and not currDate:IsLaterThan(finDate) do
				count = count + 1
				currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
				x = oTree.ganttGrid:IsVisible(0,count)
				--x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
			end

			local corner = oTree.ganttGrid:GetGridCornerLabelWindow()
			corner:DestroyChildren()
			-- Add the Month and year in the corner
			local sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local textLabel = wx.wxStaticText(corner, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			textLabel:SetLabel(currDate:Format("%b %Y"))
			sizer:Add(textLabel, 1, wx.wxLEFT+wx.wxRIGHT+wx.wxALIGN_CENTRE_VERTICAL, 3)
			corner:SetSizer(sizer)
			corner:Layout()	
			oTree.startDate = oTree.startDate:Subtract(wx.wxDateSpan(0,0,0,count))			
		end
	end
	
	local function horSashAdjustFunc(event)
		--local info = "Sash: "..tostring(Karm.GUI.horSplitWin:GetSashPosition()).."\nCol 0: "..tostring(Karm.GUI.treeGrid:GetColSize(0)).."\nCol 1 Before: "..tostring(Karm.GUI.treeGrid:GetColSize(1))
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		oTree.treeGrid:SetColMinimalWidth(1,oTree.horSplitWin:GetSashPosition()-oTree.treeGrid:GetColSize(0)-oTree.treeGrid:GetRowLabelSize(0))
		oTree.treeGrid:AutoSizeColumn(1,false)
		--info = info.."\nCol 1 After: "..tostring(Karm.GUI.treeGrid:GetColSize(1))
		--Karm.GUI.taskDetails:SetValue(info)	
		event:Skip()
	end
	
	local function widgetResizeFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local winSize = event:GetSize()
		local wid = 0.3*winSize:GetWidth()
		if wid > 400 then
			wid = 400
		end
		oTree.horSplitWin:SetSashPosition(wid)
		oTree.treeGrid:SetColMinimalWidth(1,oTree.horSplitWin:GetSashPosition()-oTree.treeGrid:GetColSize(0)-oTree.treeGrid:GetRowLabelSize(0))
		oTree.treeGrid:AutoSizeColumn(1,false)
		event:Skip()
	end
	
	local function cellClickFunc(event)
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		local col = event:GetCol()
		if row>-1 then
			if col == 1 then
				local taskNode
				-- Find the task associated with the row
				for i,v in taskTreeINT.tpairs(obj) do
					v.Selected = false	-- Make everything else unselected
					if v.Row == row+1 then
						taskNode = v
					end
				end		-- Looping through all the nodes ends
				-- print("Clicked row "..tostring(row))
				taskNode.Selected = true
				taskTreeINT[obj].Selected = {taskNode,Latest=1}
				if taskTreeINT[obj].cellClickCallBack then
					taskTreeINT[obj].cellClickCallBack(taskNode.Task, row, col)
				end
			else
				taskTreeINT[obj].Selected = {}
			end
			taskTreeINT[obj].treeGrid:SetGridCursor(row,col)
		end		
		--taskTreeINT[obj].treeGrid:SelectBlock(row,col,row,col)
		--event:Skip()
	end
	
	local function ganttCellDblClickFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local row = event:GetRow()
		local col = event:GetCol()
		-- Find the date on which clicked
		local colCount = 0					
		local stepDate = Karm.Utility.XMLDate2wxDateTime(Karm.Utility.toXMLDate(taskTreeINT[obj].startDate:Format("%m/%d/%Y")))
		while colCount < col do
			stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
			colCount = colCount + 1
		end
		if oTree.ganttCellDblClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			oTree.ganttCellDblClickCallBack(taskNode.Task, row, col, Karm.Utility.toXMLDate(stepDate:Format("%m/%d/%Y")))
		end
	end
	
	local function ganttCellClickFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local row = event:GetRow()
		local col = event:GetCol()
		local colCount = 0					
		local stepDate = Karm.Utility.XMLDate2wxDateTime(Karm.Utility.toXMLDate(taskTreeINT[obj].startDate:Format("%m/%d/%Y")))
		while colCount < col do
			stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
			colCount = colCount + 1
		end
		if taskTreeINT[obj].Planning then
			if row > -1 then
				for i = 1,#oTree.taskList do
					if oTree.Nodes[oTree.taskList[i].TaskID].Row == row+1 then
						-- This is the task modify/add the planning schedule
						Karm.TaskObject.togglePlanningDate(oTree.taskList[i],Karm.Utility.toXMLDate(stepDate:Format("%m/%d/%Y")),oTree.Planning)
						dispGanttFunc(obj,row+1,false,oTree.Nodes[oTree.taskList[i].TaskID])
						break
					end
				end
			end		-- if row > -1 then ends
		end		-- if taskTreeINT[obj].Planning then ends
		oTree.ganttGrid:SetGridCursor(event:GetRow(),event:GetCol())
		if taskTreeINT[obj].ganttCellClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].ganttCellClickCallBack(taskNode.Task, row, col, Karm.Utility.toXMLDate(stepDate:Format("%m/%d/%Y")))
		end
		cellClickFunc(wx.wxGridEvent(event:GetId(),wx.wxEVT_GRID_CELL_LEFT_CLICK,oTree.treeGrid,event:GetRow(),1))
	end		-- local function ganttCellClickFunc(event) ends
	
	ganttCellClick = ganttCellClickFunc
	ganttCellDblClick = ganttCellDblClickFunc
	ganttLabelClick = ganttLabelClickFunc
	cellClick = cellClickFunc
	widgetResize = widgetResizeFunc
	horSashAdjust = horSashAdjustFunc
	onScrollGantt = onScrollGanttFunc
	onScrollTree = onScrollTreeFunc
	labelClick = labelClickFunc
	
end	-- The custom tree and Gantt widget object for Karm ends here

-- Function to generate and return the node color of a TaskTree node
function Karm.GUI.getNodeColor(node)
	-- Get the node colors according to the status
	if not node.Task then
		return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
	else
		if Karm.Globals.StatusNodeColor then
			for i = 1,#Karm.Globals.StatusList do
				if node.Task.Status == Karm.Globals.StatusList[i] and Karm.Globals.StatusNodeColor[i] then
					local foreColor = Karm.GUI.nodeForeColor
					local backColor = Karm.GUI.nodeBackColor
					if Karm.Globals.StatusNodeColor[i].ForeColor and Karm.Globals.StatusNodeColor[i].ForeColor.Red and 
					  Karm.Globals.StatusNodeColor[i].ForeColor.Blue and Karm.Globals.StatusNodeColor[i].ForeColor.Green then
						foreColor = Karm.Globals.StatusNodeColor[i].ForeColor
					end
					if Karm.Globals.StatusNodeColor[i].BackColor and Karm.Globals.StatusNodeColor[i].BackColor.Red and 
					  Karm.Globals.StatusNodeColor[i].BackColor.Blue and Karm.Globals.StatusNodeColor[i].BackColor.Green then
						backColor = Karm.Globals.StatusNodeColor[i].BackColor
					end
					return foreColor, backColor
				end
			end
			return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
		else
			return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
		end	
	end
end

function Karm.GUI.addSpore(key,Spore)
	-- Add the spore node
	Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY, Relation="Child", Key=Karm.Globals.ROOTKEY..key, Text=Spore.Title, Task = Spore}
	Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key].ForeColor,Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key])
	local taskList = Karm.FilterObject.applyFilterHier(Karm.Filter, Spore)
	-- Now add the tasks under the spore in the TaskTree
	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore
	    -- Add the 1st element under the spore
	    local currNode = Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY..key, Relation="Child", Key=taskList[1].TaskID, 
	    		Text=taskList[1].Title, Task=taskList[1]}
		currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
	    for intVar = 2,taskList.count do
	    	local cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..key
	    	local cond2 = #taskList[intVar].TaskID > #currNode.Key
	    	local cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
	    	while cond1 and not (cond2 and cond3) do
	        	-- Go up the hierarchy
	        	currNode = currNode.Parent
	        	cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..key
	        	cond2 = #taskList[intVar].TaskID > #currNode.Key
	        	cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
	        end
	    	-- Now currNode has the node which is the right parent
	        currNode = Karm.GUI.taskTree:AddNode{Relative=currNode.Key, Relation="Child", Key=taskList[intVar].TaskID, 
	        		Text=taskList[intVar].Title, Task = taskList[intVar]}
	    	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
	    end
	end  -- if taskList.count > 0 then ends
end

--****f* Karm/Karm.GUI.fillTaskTree
-- FUNCTION
-- Function to recreate the task tree based on the global filter criteria from all the loaded spores
--
-- SOURCE
function Karm.GUI.fillTaskTree()
-- ALGORITHM

	local prevSelect, restorePrev
	local expandedStatus = {}
	Karm.GUI.taskTree.update = false		-- stop GUI updates for the time being    
    if Karm.GUI.taskTree.nodeCount > 0 then
-- Check if the task Tree has elements then get the current selected nodekey this will be selected again after the tree view is refreshed
        for i,v in Karm.GUI.taskTree.tpairs(Karm.GUI.taskTree) do
        	if v.Expanded then
        		-- NOTE: i is the same as the TaskID i.e. i == Karm.GUI.taskTree.Nodes[i].Task.TaskID
            	expandedStatus[i] = true
            end
            if v.Selected then
                prevSelect = i
            end
        end
        restorePrev = true
    end
    
-- Clear the treeview and add the root element
    Karm.GUI.taskTree:Clear()
    Karm.GUI.taskTree:AddNode{Key=Karm.Globals.ROOTKEY, Text = "Task Spores"}
    Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].ForeColor, Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY])

    if Karm.SporeData[0] > 0 then
-- Populate the tree control view
        for k,v in pairs(Karm.SporeData) do
        	if k~=0 then
            -- Get the tasks in the spore
-- Add the spore to the TaskTree
				Karm.GUI.addSpore(k,v)
			end		-- if k~=0 then ends
-- Repeat for all spores
        end		-- for k,v in pairs(Karm.SporeData) do ends
    end  -- if Karm.SporeData[0] > 0 then ends
    local selected
    if restorePrev then
-- Update the tree status to before the refresh
        for k,currNode in Karm.GUI.taskTree.tpairs(Karm.GUI.taskTree) do
            if expandedStatus[currNode.Key] then
                currNode.Expanded = true
			end
        end
        for k,currNode in Karm.GUI.taskTree.tvpairs(Karm.GUI.taskTree) do
            if currNode.Key == prevSelect then
                currNode.Selected = true
                selected = currNode.Task
            end
        end
    else
 		Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].Expanded = true
    end
	Karm.GUI.taskTree.update = true		-- Resume the tasktree update    
	-- Update the Filter summary
	if Karm.Filter then
		Karm.GUI.taskFilter:SetValue(Karm.FilterObject.getSummary(Karm.Filter))
	else
	    Karm.GUI.taskFilter:SetValue("No Filter")
	end
    Karm.GUI.taskDetails:SetValue(Karm.TaskObject.getSummary(selected))
end
--@@END@@

function Karm.GUI.frameResize(event)
	local winSize = event:GetSize()
	local hei = 0.6*winSize:GetHeight()
	if winSize:GetHeight() - hei > 400 then
		hei = winSize:GetHeight() - 400
	end
	Karm.GUI.vertSplitWin:SetSashPosition(hei)
	event:Skip()
end

function Karm.GUI.dateRangeChangeEvent(event)
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local finDate = Karm.GUI.dateFinPick:GetValue()
	Karm.GUI.taskTree:dateRangeChange(startDate,finDate)
	event:Skip()
end

function Karm.GUI.dateRangeChange()
	-- Clear the GanttGrid
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local finDate = Karm.GUI.dateFinPick:GetValue()
	Karm.GUI.taskTree:dateRangeChange(startDate,finDate)
end

function Karm.createNewSpore(title)
	local SporeName
	if title then
		SporeName = title
	else
		SporeName = wx.wxGetTextFromUser("Enter the New Spore File name under which to move the task (Blank to cancel):", "New Spore", "")
	end
	if SporeName == "" then
		return
	end
	Karm.SporeData[SporeName] = Karm.XML2Data({[0]="Task_Spore"}, SporeName)
	Karm.SporeData[SporeName].Modified = "YES"
	Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY, Relation="Child", Key=Karm.Globals.ROOTKEY..SporeName, Text=SporeName, Task = Karm.SporeData[SporeName]}
	Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].ForeColor, Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName])
	Karm.Globals.unsavedSpores[SporeName] = Karm.SporeData[SporeName].Title
	return Karm.Globals.ROOTKEY..SporeName
end

-- For MoveTask it needs the following information
--	Karm.GUI.MoveTask.action = ID
--	Karm.GUI.MoveTask.task = taskList[1].Task
-- For CopyTask it needs the following information
--	Karm.GUI.CopyTask.action = ID
--	Karm.GUI.CopyTask.task = taskList[1].Task
function Karm.moveCopyTask(task)
	-- Do the move/copy task here
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
		-- Cancel the move/copy
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.MoveTask = nil
		Karm.GUI.CopyTask = nil
		Karm.GUI.ResetMoveTools()
		Karm.GUI.ResetCopyTools()
        return
	end			
	if #taskList > 1 then
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.MoveTask = nil
		Karm.GUI.CopyTask = nil
		-- Cancel the move/copy
		Karm.GUI.ResetMoveTools()
		Karm.GUI.ResetCopyTools()
        return
	end		
	if Karm.GUI.MoveTask and taskList[1].Task ~= Karm.GUI.MoveTask.task or Karm.GUI.CopyTask and taskList[1].Task ~= Karm.GUI.CopyTask.task then
		-- Start the move/copy
		if taskList[1].Key == Karm.Globals.ROOTKEY then
			-- Relative is the Root node
			if Karm.GUI.MoveTask and (Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_ABOVE or Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_BELOW) then
				wx.wxMessageBox("Can only move a task under the root task!","Illegal Move", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
			if Karm.GUI.CopyTask and (Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_ABOVE or Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_BELOW) then
				wx.wxMessageBox("Can only copy a task under the root task!","Illegal Copy", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
			-- This is to move/copy the task into a new Spore
			-- Create a new Spore here and make that the target parent instead of the root node
			taskList[1] = Karm.GUI.taskTree.Nodes[Karm.createNewSpore()]
		end
		local task, str 
		if Karm.GUI.MoveTask then
			task = Karm.GUI.MoveTask.task
			str = "Move"
		else
			-- Make a copy of the task and all its sub tasks and remove any DBDATA from the task to make a new task
			task = Karm.TaskObject.copy(Karm.GUI.CopyTask.task, true, true)
			str = "Copy"
		end
		if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- Relative is Spore
			if (Karm.GUI.MoveTask and (Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_ABOVE or Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_BELOW))
			  or (Karm.GUI.CopyTask and (Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_ABOVE or Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_BELOW)) then
				-- Create a new spore and move/copy it under there (set that the new target parent)
				taskList[1] = Karm.GUI.taskTree.Nodes[Karm.createNewSpore()]
			end
			-- This is to move/copy the task into this spore
			local taskID
			-- Get a new task ID
			taskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", str.." Task Under Spore", "")
			if taskID == "" then
				-- Cancel the move/copy
				Karm.GUI.statusBar:SetStatusText("",0)
				Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
				Karm.GUI.MoveTask = nil
				Karm.GUI.CopyTask = nil
				return
			end
			-- Check if the task ID exists in all the loaded spores
			while true do
				local redo = nil
				for k,v in pairs(Karm.SporeData) do
        			if k~=0 then
						local list = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=taskID}}}, v)
						if #list > 0 then
							redo = true
							break
						end
					end
				end
				if redo then
					taskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", str.." Task Under Spore", "")
					if taskID == "" then
						-- Cancel the move/copy
						Karm.GUI.statusBar:SetStatusText("",0)
						Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
						Karm.GUI.MoveTask = nil
						Karm.GUI.CopyTask = nil
						return
					end
				else
					break
				end
			end		
			
			if Karm.GUI.MoveTask then	
				-- Delete it from db
				-- Delete from Spores
				-- Parent of a root node is nil
				Karm.TaskObject.DeleteFromDB(task)
				-- Delete from task Tree GUI
				Karm.GUI.taskTree:DeleteTree(task.TaskID)
			end
			Karm.TaskObject.updateTaskID(task,taskID)
			task.Parent = nil
			task.SporeFile = string.sub(taskList[1].Key,#Karm.Globals.ROOTKEY+1,-1)
			Karm.GUI.TaskWindowOpen = {Spore = true, Relative = taskList[1].Key, Relation = "Child"}
			Karm.NewTaskCallBack(task)		-- This takes care of adding the task to the database and also displaying this task		
			if task.SubTasks then
				-- Update the SubTasks parent
				task.SubTasks.parent = Karm.SporeData[task.SporeFile]
				-- Update the Spore file in all sub tasks
				local list1 = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[task.SporeFile])
				if #list1 > 0 then
					for i = 1,#list1 do
						list1[i].SporeFile = task.SporeFile
					end
				end					
				-- Now add all the Child hierarchy of the moved task to the GUI
				local addList = Karm.FilterObject.applyFilterHier(Karm.Filter, task.SubTasks)
				-- Now add the tasks under the spore in the TaskTree
            	if addList.count > 0 then  --There are some tasks passing the criteria in this spore
    	            local currNode = Karm.GUI.taskTree.Nodes[task.TaskID]
	                for intVar = 1,addList.count do
	                	local cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..task.SporeFile
	                	local cond2 = #addList[intVar].TaskID > #currNode.Key
	                	local cond3 = string.sub(addList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                    	while cond1 and not (cond2 and cond3) do
                        	-- Go up the hierarchy
                        	currNode = currNode.Parent
		                	cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..task.SporeFile
		                	cond2 = #addList[intVar].TaskID > #currNode.Key
		                	cond3 = string.sub(addList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                        end
                    	-- Now currNode has the node which is the right parent
	                    currNode = Karm.GUI.taskTree:AddNode{Relative=currNode.Key, Relation="Child", Key=addList[intVar].TaskID, 
	                    		Text=addList[intVar].Title, Task = addList[intVar]}
                    	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
                    end
	            end  -- if addList.count > 0 then ends
			end		-- if task.SubTasks then ends
		else		-- if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- This is to move/copy the task in relation to this task
			-- This relative might be a Spore root task or a normal hierarchy task
			if Karm.GUI.MoveTask and Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_UNDER or Karm.GUI.CopyTask and Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_UNDER then
				-- Sub task handling is same in both cases
				if Karm.GUI.MoveTask then
					-- Delete it from db
					-- Delete from Spores
					Karm.TaskObject.DeleteFromDB(task)
					-- Delete from task Tree GUI
					Karm.GUI.taskTree:DeleteTree(task.TaskID)
				end
				Karm.TaskObject.updateTaskID(task, Karm.TaskObject.getNewChildTaskID(taskList[1].Task))
				task.Parent = taskList[1].Task
				Karm.GUI.TaskWindowOpen = {Relative = taskList[1].Key, Relation = "Child"}
			else		-- if Karm.GUI.MoveTask and Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_UNDER or Karm.GUI.CopyTask and Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_UNDER then else
				local parent, taskID
				if not taskList[1].Task.Parent then
					-- This is a spore root node so will have to ask for the task ID from the user
					taskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", str.." Task", "")
					if taskID == "" then
						-- Cancel the move
						Karm.GUI.statusBar:SetStatusText("",0)
						Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
						Karm.GUI.MoveTask = nil
						Karm.GUI.CopyTask = nil
						return
					end
					-- Check if the task ID exists in all the loaded spores
					while true do
						local redo = nil
						for k,v in pairs(Karm.SporeData) do
		        			if k~=0 then
								local list = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=taskID}}}, v)
								if #list > 0 then
									redo = true
									break
								end
							end
						end
						if redo then
							taskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", str.." Task", "")
							if taskID == "" then
								-- Cancel the move
								Karm.GUI.statusBar:SetStatusText("",0)
								Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
								Karm.GUI.MoveTask = nil
								Karm.GUI.CopyTask = nil
								return
							end
						else
							break
						end
					end		
					-- Parent of a root node is nil	
				else				
					taskID = Karm.TaskObject.getNewChildTaskID(taskList[1].Task.Parent)
					parent = taskList[1].Task.Parent
				end		-- if not taskList[1].Task.Parent then ends
				if Karm.GUI.MoveTask and Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_ABOVE or Karm.GUI.CopyTask and Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_ABOVE then
					-- Move/Copy Above
					Karm.GUI.TaskWindowOpen = {Relative = taskList[1].Key, Relation = "PREV SIBLING"}
				else
					-- Move?Copy Below
					Karm.GUI.TaskWindowOpen = {Relative = taskList[1].Key, Relation = "NEXT SIBLING"}
				end
				if Karm.GUI.MoveTask then
					-- Delete it from db
					-- Delete from Spores
					Karm.TaskObject.DeleteFromDB(task)
					-- Delete from task Tree Karm.GUI
					Karm.GUI.taskTree:DeleteTree(task.TaskID)
				end
				Karm.TaskObject.updateTaskID(task,taskID)
				task.Parent = parent
			end		-- if Karm.GUI.MoveTask and Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_UNDER or Karm.GUI.CopyTask and Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_UNDER then ends				
			task.SporeFile = taskList[1].Task.SporeFile
			Karm.NewTaskCallBack(task)		-- This takes care of adding the task to the database and also displaying this task
			if task.SubTasks then
				-- update the SubTasks parent
				task.SubTasks.parent = taskList[1].Task.SubTasks
				-- Update the Spore file in all sub tasks
				local list1 = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[task.SporeFile])
				if #list1 > 0 then
					for i = 1,#list1 do
						list1[i].SporeFile = task.SporeFile
					end
				end										
				-- Now add all the Child hierarchy of the moved task to the GUI
				local addList = Karm.FilterObject.applyFilterHier(Karm.Filter, task.SubTasks)
				-- Now add the tasks under the spore in the TaskTree
            	if addList.count > 0 then  --There are some tasks passing the criteria in this spore
    	            local currNode = Karm.GUI.taskTree.Nodes[task.TaskID]
	                for intVar = 1,addList.count do
	                	local cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..task.SporeFile
	                	local cond2 = #addList[intVar].TaskID > #currNode.Key
	                	local cond3 = string.sub(addList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                    	while cond1 and not (cond2 and cond3) do
                        	-- Go up the hierarchy
                        	currNode = currNode.Parent
		                	cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..task.SporeFile
		                	cond2 = #addList[intVar].TaskID > #currNode.Key
		                	cond3 = string.sub(addList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                        end
                    	-- Now currNode has the node which is the right parent
	                    currNode = Karm.GUI.taskTree:AddNode{Relative=currNode.Key, Relation="Child", Key=addList[intVar].TaskID, 
	                    		Text=addList[intVar].Title, Task = addList[intVar]}
                    	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
                    end
	            end  -- if addList.count > 0 then ends
			end		-- if task.SubTasks then ends
		end		-- if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then ends
		Karm.Globals.unsavedSpores[taskList[1].Task.SporeFile] = Karm.SporeData[taskList[1].Task.SporeFile].Title
		if Karm.GUI.MoveTask then
			Karm.Globals.unsavedSpores[Karm.GUI.MoveTask.task.SporeFile] = Karm.SporeData[Karm.GUI.MoveTask.task.SporeFile].Title
		else
			Karm.Globals.unsavedSpores[Karm.GUI.CopyTask.task.SporeFile] = Karm.SporeData[Karm.GUI.CopyTask.task.SporeFile].Title
		end
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.MoveTask = nil
		Karm.GUI.CopyTask = nil
		-- Finish the move
		Karm.GUI.ResetMoveTools()
		Karm.GUI.ResetCopyTools()
	end		-- if Karm.GUI.MoveTask and taskList[1].Task ~= Karm.GUI.MoveTask.task or Karm.GUI.CopyTask and taskList[1].Task ~= Karm.GUI.CopyTask.task then ends
end		-- function Karm.moveCopyTask ends

function Karm.GUI.taskClicked(task)
	Karm.GUI.taskDetails:SetValue(Karm.TaskObject.getSummary(task))
	if Karm.GUI.MoveTask or Karm.GUI.CopyTask then
		Karm.moveCopyTask(task)
	end		-- if Karm.GUI.MoveTask then ends here
end		-- function taskClicked(task) ends here

function Karm.SetFilterCallBack(filter)
	Karm.GUI.FilterWindowOpen = false
	if filter then
		Karm.Filter = filter
		Karm.GUI.fillTaskTree()
	end
end

function Karm.SetFilter(event)
	if not Karm.GUI.FilterWindowOpen then
		Karm.GUI.FilterForm.filterFormActivate(Karm.GUI.frame,Karm.SetFilterCallBack)
		Karm.GUI.FilterWindowOpen = true
	else
		Karm.GUI.FilterForm.frame:SetFocus()
	end
end

-- Relative = relative of this new node (should be a task ID) 
-- Relation = relation of this new node to the Relative. This can be "Child", "Next Sibling", "Prev Sibling" 
function Karm.NewTaskCallBack(task)
	if task then
		if AutoFillTask then
			AutoFillTask(task)
		end
		if Karm.GUI.TaskWindowOpen.Spore then
			-- Add child to Spore i.e. Create a new root task in the spore
			-- Add the task to the Karm.SporeData
			Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
		else
			-- Normal Hierarchy add
			if Karm.GUI.TaskWindowOpen.Relation:upper() == "CHILD" then
				-- Add child
				Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
			elseif Karm.GUI.TaskWindowOpen.Relation:upper() == "NEXT SIBLING" then
				-- Add as next sibling
				if not task.Parent then
					-- Task is a root task in a spore
					Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"AFTER",Karm.SporeData[task.SporeFile])
				else
					-- First add as child
					Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"AFTER")
					-- Now modify the GUI keys
					local currNode = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Parent.LastChild
					local relative = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative]
					while currNode ~= relative do
						Karm.GUI.taskTree:UpdateKeys(currNode)
						currNode = currNode.Prev					
					end
				end		-- if not task.Parent then ends here
			else
				-- Add as previous sibling
				if not task.Parent then
					-- Task is a root spore node
					Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"BEFORE",Karm.SporeData[task.SporeFile])
				else
					-- First add as child
					Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"BEFORE")
					-- Now modify the Karm.GUI keys and add it to the UI
					local currNode = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Parent.LastChild
					local relative = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative]
					while currNode ~= relative do
						Karm.GUI.taskTree:UpdateKeys(currNode)
						currNode = currNode.Prev					
					end
					-- Move the relative also
					Karm.GUI.taskTree:UpdateKeys(currNode)
					-- Since the Relative ID has changed update the ID in TaskWindowOpen here
					Karm.GUI.TaskWindowOpen.Relative = currNode.Key
				end		-- if not task.Parent then ends here
			end		-- if Karm.GUI.TaskWindowOpen.Relation:upper() == "CHILD" then ends here
		end		-- if Karm.GUI.TaskWindowOpen.Spore then ends here
		local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
		if #taskList == 1 then
		    Karm.GUI.taskTree:AddNode{Relative=Karm.GUI.TaskWindowOpen.Relative, Relation=Karm.GUI.TaskWindowOpen.Relation, Key=task.TaskID, Text=task.Title, Task=task}
	    	Karm.GUI.taskTree.Nodes[task.TaskID].ForeColor, Karm.GUI.taskTree.Nodes[task.TaskID].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[task.TaskID])
	    end
		Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
    end		-- if task then ends
	Karm.GUI.TaskWindowOpen = false
end

function Karm.EditTaskCallBack(task)
	if task then
		-- Replace task into Karm.GUI.TaskWindowOpen.Task
		if not Karm.GUI.TaskWindowOpen.Task.Parent then
			-- This is a root task in the Spore
			local Spore = Karm.SporeData[Karm.GUI.TaskWindowOpen.Task.SporeFile]
			for i=1,#Spore do
				if Spore[i] == Karm.GUI.TaskWindowOpen.Task then
					Spore[i] = task
					break
				end
			end
		else
			local parentTask = Karm.GUI.TaskWindowOpen.Task.Parent
			for i=1,#parentTask.SubTasks do
				if parentTask.SubTasks[i] == Karm.GUI.TaskWindowOpen.Task then
					parentTask.SubTasks[i] = task
					break
				end
			end
		end
		-- Update the task in the Karm.GUI here
		-- Check if the task passes the filter now
		local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
		if #taskList == 1 then
			-- It passes the filter so update the task
		    Karm.GUI.taskTree:UpdateNode(task)
			Karm.GUI.taskTree.Nodes[task.TaskID].ForeColor, Karm.GUI.taskTree.Nodes[task.TaskID].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[task.TaskID])
			Karm.GUI.taskClicked(task)
	    else
	    	-- Delete the task node and adjust the hier level of all the sub task hierarchy if any
	    	Karm.GUI.taskTree:DeleteSubUpdate(task.TaskID)
	    end
		Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
	end
	Karm.GUI.TaskWindowOpen = false
end

function Karm.DeleteTask(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	for i = 1,#taskList do
		if taskList[i].Key == Karm.Globals.ROOTKEY then
			-- Root node  deleting requested
			wx.wxMessageBox("Cannot delete the root node!","Root Node Deleting", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		end
	end	
	local confirm
	if #taskList > 1 then
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"Are you sure you want to delete all selected tasks and all their child elements?", "Confirm Multiple Delete", wx.wxYES_NO + wx.wxNO_DEFAULT)
	else
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"Are you sure you want to delete this task:\n"..taskList[1].Title.."\n and all its child elements?", "Confirm Delete", wx.wxYES_NO + wx.wxNO_DEFAULT)
	end
	local response = confirm:ShowModal()
	if response == wx.wxID_YES then
		for i = 1,#taskList do
			-- Delete from Spores
			if taskList[i].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
				-- This is a Spore node
				Karm.SporeData[taskList[i].Key:sub(#Karm.Globals.ROOTKEY+1,-1)] = nil
				Karm.SporeData[0] = Karm.SporeData[0] - 1
				Karm.Globals.unsavedSpores[taskList[i].Key:sub(#Karm.Globals.ROOTKEY+1,-1)] = nil
			else
				-- This is a normal task
				Karm.TaskObject.DeleteFromDB(taskList[i].Task)
				Karm.Globals.unsavedSpores[taskList[i].Task.SporeFile] = Karm.SporeData[taskList[i].Task.SporeFile].Title
			end
			Karm.GUI.taskTree:DeleteTree(taskList[i].Key)
		end
	end
end

function Karm.CopyTaskToggle(event)
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_BELOW,nil)
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end			
	if #taskList > 1 then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_BELOW,nil)
        wx.wxMessageBox("Just select a single task to copy.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end	
	if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_BELOW,nil)
		wx.wxMessageBox("Cannot copy the root node or a Spore node. Please select a task to be copied.", "No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		return
	end	
	Karm.GUI.ResetMoveTools()
	Karm.GUI.CopyTask = {}
	-- Check if any other button is toggled then reset that button
	local ID = event:GetId()
	Karm.GUI.CopyTask.action = ID
	Karm.GUI.CopyTask.task = taskList[1].Task
	local ID1, ID2, status
	if ID == Karm.GUI.ID_COPY_UNDER then
		ID1 = Karm.GUI.ID_COPY_ABOVE
		ID2 = Karm.GUI.ID_COPY_BELOW
		status = "COPY TASK: Click task to copy this task under..."
	elseif ID == Karm.GUI.ID_COPY_ABOVE then
		ID1 = Karm.GUI.ID_COPY_UNDER
		ID2 = Karm.GUI.ID_COPY_BELOW
		status = "COPY TASK: Click task to copy this task above..."
	else
		ID1 = Karm.GUI.ID_COPY_ABOVE
		ID2 = Karm.GUI.ID_COPY_UNDER
		status = "COPY TASK: Click Task to copy this task below..."
	end	
	if Karm.GUI.toolbar:GetToolState(ID1) then
		Karm.GUI.toolbar:ToggleTool(ID1,nil)
	end
	if Karm.GUI.toolbar:GetToolState(ID2) then
		Karm.GUI.toolbar:ToggleTool(ID2,nil)
	end
	if not (Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_COPY_ABOVE) or Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_COPY_UNDER) or Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_COPY_BELOW)) then
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.CopyTask = nil
		return
	end
	Karm.GUI.frame:SetStatusText(status,0)
	Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.highLightColor.Red,Karm.GUI.highLightColor.Green,Karm.GUI.highLightColor.Blue))
end

function Karm.MoveTaskToggle(event)
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end			
	if #taskList > 1 then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
        wx.wxMessageBox("Just select a single task to move.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end	
	if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
		wx.wxMessageBox("Cannot move the root node or a Spore node. Please select a task to be moved.", "No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		return
	end	
	Karm.GUI.ResetCopyTools()
	Karm.GUI.MoveTask = {}
	-- Check if any other button is toggled then reset that button
	local ID = event:GetId()
	Karm.GUI.MoveTask.action = ID
	Karm.GUI.MoveTask.task = taskList[1].Task
	local ID1, ID2, status
	if ID == Karm.GUI.ID_MOVE_UNDER then
		ID1 = Karm.GUI.ID_MOVE_ABOVE
		ID2 = Karm.GUI.ID_MOVE_BELOW
		status = "MOVE TASK: Click task to move this task under..."
	elseif ID == Karm.GUI.ID_MOVE_ABOVE then
		ID1 = Karm.GUI.ID_MOVE_UNDER
		ID2 = Karm.GUI.ID_MOVE_BELOW
		status = "MOVE TASK: Click task to move this task above..."
	else
		ID1 = Karm.GUI.ID_MOVE_ABOVE
		ID2 = Karm.GUI.ID_MOVE_UNDER
		status = "MOVE TASK: Click Task to move this task below..."
	end	
	if Karm.GUI.toolbar:GetToolState(ID1) then
		Karm.GUI.toolbar:ToggleTool(ID1,nil)
	end
	if Karm.GUI.toolbar:GetToolState(ID2) then
		Karm.GUI.toolbar:ToggleTool(ID2,nil)
	end
	if not (Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_MOVE_ABOVE) or Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_MOVE_UNDER) or Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_MOVE_BELOW)) then
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.MoveTask = nil
		return
	end
	Karm.GUI.frame:SetStatusText(status,0)
	Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.highLightColor.Red,Karm.GUI.highLightColor.Green,Karm.GUI.highLightColor.Blue))
end

function Karm.GUI.ResetCopyTools()
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_UNDER,nil)
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_ABOVE,nil)
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_BELOW,nil)
end

function Karm.GUI.ResetMoveTools()
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
end

function Karm.GUI.ResetToggleTools()
	Karm.GUI.ResetMoveTools()
	Karm.GUI.ResetCopyTools()
end

function Karm.EditTask(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	if not Karm.GUI.TaskWindowOpen then
		-- Get the selected task
		local taskList = Karm.GUI.taskTree.Selected
		if #taskList == 0 then
            wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end			
		if #taskList > 1 then
            wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end		
		-- Get the new task task ID
		local taskID = taskList[1].Key
		if taskID == Karm.Globals.ROOTKEY then
			-- Root node editing requested
			wx.wxMessageBox("Nothing editable in the root node","Root Node Editing", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		elseif taskID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- Spore node editing requested
			wx.wxMessageBox("Nothing editable in the spore node","Spore Node Editing", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		else
			-- A normal task editing requested
			Karm.GUI.TaskWindowOpen = {Task = taskList[1].Task}
			Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.EditTaskCallBack,taskList[1].Task)
		end
	end
end

function Karm.NewTask(event, title)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	if not Karm.GUI.TaskWindowOpen then
		local taskList = Karm.GUI.taskTree.Selected
		if #taskList == 0 then
            wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end			
		if #taskList > 1 then
            wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end		
		-- Get the new task task ID
		local relativeID = taskList[1].Key
		local task = {}
		-- There are 4 levels that need to be handled
		-- 1. Root node on the tree
		-- 2. Spore Node
		-- 3. Root task node in a Spore
		-- 4. Normal task node
		if relativeID == Karm.Globals.ROOTKEY then
			-- 1. Root node on the tree
			if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK or event:GetId() == Karm.GUI.ID_NEW_NEXT_TASK then
	            wx.wxMessageBox("A sibling for the root node cannot be created.","Root Node Sibling", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	            return
			end						
			-- This is the root so the request is to create a new spore
			Karm.createNewSpore(title)
		elseif relativeID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- 2. Spore Node
			if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK or event:GetId() == Karm.GUI.ID_NEW_NEXT_TASK then
				local SporeName
				if title then
					SporeName = title
				else
					SporeName = wx.wxGetTextFromUser("Enter the Spore File name (Blank to cancel):", "New Spore", "")
				end
				if SporeName == "" then
					return
				end
				Karm.SporeData[SporeName] = Karm.XML2Data({[0]="Task_Spore"}, SporeName)
				Karm.SporeData[SporeName].Modified = true
				Karm.SporeData[0] = Karm.SporeData[0] + 1
				if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK then
	            	Karm.GUI.taskTree:AddNode{Relative=relativeID, Relation="PREV SIBLING", Key=Karm.Globals.ROOTKEY..SporeName, Text=SporeName, Task = Karm.SporeData[SporeName]}
	            else
	            	Karm.GUI.taskTree:AddNode{Relative=relativeID, Relation="NEXT SIBLING", Key=Karm.Globals.ROOTKEY..SporeName, Text=SporeName, Task = Karm.SporeData[SporeName]}
	            end
	            Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].ForeColor, Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName])	
			else
				-- This is a Spore so the request is to create a new root task in the spore
				task.TaskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", "New Task", "")
				if task.TaskID == "" then
					return
				end
				-- Check if the task ID exists in all the loaded spores
				while true do
					local redo = nil
					for k,v in pairs(Karm.SporeData) do
	        			if k~=0 then
							local taskList = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=task.TaskID}}}, v)
							if #taskList > 0 then
								redo = true
								break
							end
						end
					end
					if redo then
						task.TaskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", "New Task", "")
						if task.TaskID == "" then
							return
						end
					else
						break
					end
				end		
				-- Parent of a root node is nil		
				task.SporeFile = string.sub(Karm.GUI.taskTree.Nodes[relativeID].Key,#Karm.Globals.ROOTKEY+1,-1)
				Karm.GUI.TaskWindowOpen = {Spore = true, Relative = relativeID, Relation = "Child"}
				if title then
					task.Title = title
					task.Who = {[0]="Who", count = 1, [1] = {ID = Karm.Globals.User, Status = "Active"}}
					Karm.NewTaskCallBack(task)
				else
					Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.NewTaskCallBack,task)
				end
			end
		else
			-- 3. Root task node in a Spore
			-- 4. Normal task node
			-- This is a normal task so the request is to create a new task relative to this task
			if event:GetId() == Karm.GUI.ID_NEW_SUB_TASK then
				-- Sub task handling is same in both cases
				task.TaskID = Karm.TaskObject.getNewChildTaskID(Karm.GUI.taskTree.Nodes[relativeID].Task)
				task.Parent = Karm.GUI.taskTree.Nodes[relativeID].Task
				Karm.GUI.TaskWindowOpen = {Relative = relativeID, Relation = "Child"}
			else
				if not Karm.GUI.taskTree.Nodes[relativeID].Task.Parent then
					-- This is a spore root node so will have to ask for the task ID from the user
					task.TaskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", "New Task", "")
					if task.TaskID == "" then
						return
					end
					-- Check if the task ID exists in all the loaded spores
					while true do
						local redo = nil
						for k,v in pairs(Karm.SporeData) do
		        			if k~=0 then
								local taskList = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=task.TaskID}}}, v)
								if #taskList > 0 then
									redo = true
									break
								end
							end
						end
						if redo then
							task.TaskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", "New Task", "")
							if task.TaskID == "" then
								return
							end
						else
							break
						end
					end		
					-- Parent of a root node is nil	
				else				
					task.TaskID = Karm.TaskObject.getNewChildTaskID(Karm.GUI.taskTree.Nodes[relativeID].Task.Parent)
					task.Parent = Karm.GUI.taskTree.Nodes[relativeID].Task.Parent
				end
				if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK then
					Karm.GUI.TaskWindowOpen = {Relative = relativeID, Relation = "PREV SIBLING"}
				else
					Karm.GUI.TaskWindowOpen = {Relative = relativeID, Relation = "NEXT SIBLING"}
				end
			end
			task.SporeFile = Karm.GUI.taskTree.Nodes[relativeID].Task.SporeFile
			if title then
				task.Title = title
				task.Who = {[0]="Who", count = 1, [1] = {ID = Karm.Globals.User, Status = "Active"}}
				Karm.NewTaskCallBack(task)
			else
				Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.NewTaskCallBack,task)
			end
		end		-- if relativeID == Karm.Globals.ROOTKEY then ends
	else
		Karm.GUI.TaskForm.frame:SetFocus()
	end	
end

function Karm.CharKeyEvent(event)
	print("Caught Keypress")
	local kc = event:GetKeyCode()
	if kc == wx.WXK_ESCAPE then
		print("Caught Escape")
		-- Check possible ESCAPE actions
		if Karm.GUI.MoveTask then
			Karm.GUI.MoveTask = nil
			Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
			Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
			Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
		end			
	end
end

function Karm.connectKeyUpEvent(win)
	if win then
		pcall(win.Connect,win,wx.wxID_ANY, wx.wxEVT_KEY_UP, Karm.CharKeyEvent)
		local childNode = win:GetChildren():GetFirst()
		while childNode do
			Karm.connectKeyUpEvent(childNode:GetData())
			childNode = childNode:GetNext()
		end
	end
end

function Karm.SaveAllSpores(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	for k,v in pairs(Karm.SporeData) do
		if k ~= 0 then
			Karm.saveKarmSpore(k)
		end
	end
	Karm.Globals.unsavedSpores = {}
end

function Karm.saveKarmSpore(Spore)
	local file,err,path
	if Karm.SporeData[Spore].Modified then
		local notOK = true
		while notOK do
		    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Save Spore: "..Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore].Title,
		                                       "",
		                                       "",
		                                       "Karm Spore files (*.ksf)|*.ksf|Text files (*.txt)|*.txt|All files (*)|*",
		                                       wx.wxFD_SAVE)
		    if fileDialog:ShowModal() == wx.wxID_OK then
		    	if Karm.SporeData[path] then
		    		wx.wxMessageBox("Spore already exist select a different name please.","Name Conflict", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		    	else
		    		notOK = nil
			    	path = fileDialog:GetPath()
			    	file,err = io.open(path,"w+")
			    end
		    else
		    	return
		    end
		    fileDialog:Destroy()
		end
	else
		path = Spore
		file,err = io.open(path,"w+")
	end		-- if Karm.SporeData[Spore].Modified then ends
	if not file then
        wx.wxMessageBox("Unable to save as file '"..path.."'.\n "..err, "File Save Error", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    else
    	if Spore ~= path then
    		-- Update the Spore File name in all the tasks and the root Spore
			Karm.SporeData[path] = Karm.SporeData[Spore]    
			Karm.SporeData[Spore] = nil
			Karm.SporeData[path].SporeFile = path
			Karm.SporeData[path].TaskID = Karm.Globals.ROOTKEY..path
			Karm.SporeData[path].Title = Karm.sporeTitle(path)		
			Karm.GUI.taskTree:UpdateKeys(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore],true)
			Karm.GUI.taskTree:UpdateNode(Karm.SporeData[path])
			-- Now update all sub tasks
			local taskList = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[path])
			if #taskList > 0 then
				for i = 1,#taskList do
					taskList[i].SporeFile = path
				end
			end
    	end
    	Karm.SporeData[path].Modified = false
    	file:write(Karm.Utility.tableToString2(Karm.SporeData[path]))
    	file:close()
    	Karm.Globals.unsavedSpores[Spore] = nil
    end
end

function Karm.SaveCurrSpore(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task or a spore first.","No Spore Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	local Spore
	if taskList[1].Task.SporeFile then
		Spore = taskList[1].Task.SporeFile
	else
		Spore = taskList[1].Key:sub(#Karm.Globals.ROOTKEY + 1,-1)
	end
	for i = 2,#taskList do
		if taskList[i].Task.SporeFile then
			if Spore ~= taskList[i].Task.SporeFile then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		else
			if Spore ~= taskList[i].Key:sub(#Karm.Globals.ROOTKEY + 1, -1) then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		end
	end
	-- Now Spore has the Spore that needs to be Saved
	Karm.saveKarmSpore(Spore)
end

function Karm.loadXML()
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Open XML Spore file",
                                       "",
                                       "",
                                       "XML Spore files (*.xml)|*.xml|All files (*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
		Karm.SporeData[fileDialog:GetPath()] = Karm.XML2Data(xml.load(fileDialog:GetPath()), fileDialog:GetPath())
		Karm.SporeData[fileDialog:GetPath()].Modified = true
		Karm.SporeData[0] = Karm.SporeData[0] + 1
    end
    fileDialog:Destroy()
end

-- Function to load a Spore given the Spore file path in the data structure and the GUI
-- Inputs:
-- file - the file name with full path of the Spore to load
-- commands - A table containin the set of commands on behavior
--		onlyData - if true then only the Spore Data is loaded GUI is not touched or queried
--		forceReload - if true reloads the data over the existing data
-- Returns true if successful otherwise throws an error
-- Error Codes returned:
--		 1 - Spore Already loaded
-- 		 2 - Task ID in the Spore already exists in the memory
--		 3 - No valid Spore found in the file
--		 4 - File load error
function Karm.loadKarmSpore(file, commands)
	local Spore
	do
		local safeenv = {}
		setmetatable(safeenv, {__index = Karm.Globals.safeenv})
		local f,message = loadfile(file)
		if not f then
			error({msg = "loadKarmSpore:4 "..message, code = "loadKarmSpore:4"},2)
		end
		setfenv(f,safeenv)
		f()
		if Karm.validateSpore(safeenv.t0) then
			Spore = safeenv.t0
		else
			error({msg = "loadKarmSpore:3 No valid Spore found in the file", code = "loadKarmSpore:3"},2)
		end
	end
	-- Update the SporeFile in all the tasks and set the metatable
	Spore.SporeFile = file
	-- Now update all sub tasks
	local list1 = Karm.FilterObject.applyFilterHier(nil,Spore)
	if #list1 > 0 then
		for i = 1,#list1 do
			list1[i].SporeFile = Spore.SporeFile
			setmetatable(list1[i],Karm.TaskObject)
		end
	end        	
	-- First update the Karm.Globals.ROOTKEY
	Spore.TaskID = Karm.Globals.ROOTKEY..Spore.SporeFile
	-- Get list of task in the spore
	list1 = Karm.FilterObject.applyFilterHier(nil,Spore)
	local reload = nil
	-- Now check if the spore is already loaded in the dB
	for k,v in pairs(Karm.SporeData) do
		if k~=0 then
			if k == Spore.SporeFile then
				if commands.forceReload then
					-- Reload the spore
					reload = true
				else
					error({msg = "loadKarmSpore:1 Spore already loaded", code = "loadKarmSpore:1"},2)
				end
			end		-- if k == Spore.SporeFile then ends
			-- Check if any task ID is clashing with the existing tasks
			local list2 = Karm.FilterObject.applyFilterHier(nil,v)
			for i = 1,#list1 do
				for j = 1,#list2 do
					if list1[i].TaskID == list2[j].TaskID then
						error({msg = "loadKarmSpore:2 Task ID in the Spore already exists in the memory", code = "loadKarmSpore:2"},2)
					end
				end		-- for j = 1,#list2 do ends
			end		-- for i = 1,#list1 do ends
		end		-- if k~=0 then ends
	end		-- for k,v in pairs(Karm.SporeData) do ends
	if reload then
		-- Delete the current spore
		Karm.SporeData[Spore.SporeFile] = nil
		if not commands.onlyData and Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore.SporeFile] then
			Karm.GUI.taskTree:DeleteTree(Karm.Globals.ROOTKEY..Spore.SporeFile)
		end
	end
	-- Load the spore here
	Karm.SporeData[Spore.SporeFile] = Spore
	Karm.SporeData[0] = Karm.SporeData[0] + 1
	if not commands.onlyData then
		-- Load the Spore in the Karm.GUI here
		Karm.GUI.addSpore(Spore.SporeFile,Spore)
	end
	return true
end

function Karm.openKarmSpore(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Open Spore file",
                                       "",
                                       "",
                                       "Karm Spore files (*.ksf)|*.ksf|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
    	local result,message = pcall(Karm.loadKarmSpore,fileDialog:GetPath(),{})
        if not result then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.\n "..message.msg,
                            "File Load Error",
                            wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        end
    end
    fileDialog:Destroy()
end		-- function Karm.openKarmSpore(event)ends

function Karm.unloadKarmSpore(Spore)
	if not Karm.SporeData[Spore] then
		error("Cannot find the Spore:"..Spore.." in loaded data",2)
	end
	Karm.SporeData[Spore] = nil
	Karm.SporeData[0] = Karm.SporeData[0] - 1
	Karm.GUI.taskTree:DeleteTree(Karm.Globals.ROOTKEY..Spore)
	Karm.Globals.unsavedSpores[Spore] = nil
end

function Karm.unloadSpore(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task or a spore first.","No Spore Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	local Spore
	if taskList[1].Task.SporeFile then
		Spore = taskList[1].Task.SporeFile
	else
		Spore = taskList[1].Key:sub(#Karm.Globals.ROOTKEY + 1,-1)
	end
	for i = 2,#taskList do
		if taskList[i].Task.SporeFile then
			if Spore ~= taskList[i].Task.SporeFile then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		else
			if Spore ~= taskList[i].Key:sub(#Karm.Globals.ROOTKEY + 1, -1) then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		end
	end
	-- Now Spore has the Spore that needs to be unloaded
	local confirm, response
	if Karm.Globals.unsavedSpores[Spore] then
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"The spore "..Karm.Globals.unsavedSpores[Spore].." has unsaved changes. Are you sure you want to unload the spore and loose all changes?", "Loose all changes?", wx.wxYES_NO + wx.wxNO_DEFAULT)
		response = confirm:ShowModal()
	else
		response = wx.wxID_YES
	end
	if response == wx.wxID_YES then
		Karm.unloadKarmSpore(Spore)
	end
end

function Karm.GUI.menuEventHandlerFunction(ID, code, file)
	if not ID or (not code and not file) or (code and file) then
		error("menuEventHandler: invalid parameters passed, need the ID and only 1 of code chunk or file name.")
	end
	local handler
	if code then
		handler = function(event)
			local f,message = loadstring(code)
			if not f then
				error(message,1)
			end
			setfenv(f,getfenv(1))
			f()
		end
	else
		handler = function(event)
			local f,message = loadfile(file)
			if not f then
				error(message,1)
			end
			setfenv(f,getfenv(1))
			f()		
		end
	end
	return handler
end

function Karm.finalizePlanningAll(taskList)
	for i = 1,#taskList do
		Karm.finalizePlanning(taskList[i])
	end
end

-- To finalize the planning of a task and convert it to a normal schedule
function Karm.finalizePlanning(task)
	if not task.Planning then
		return
	end
	local list = Karm.TaskObject.getLatestScheduleDates(task,true)
	if list then
		local todayDate = wx.wxDateTime()
		todayDate:SetToCurrent()
		todayDate = Karm.Utility.toXMLDate(todayDate:Format("%m/%d/%Y"))	
		local list1 = Karm.TaskObject.getLatestScheduleDates(task)
		-- Compare the schedules
		local same = true
		if not list1 or #list1 ~= #list or (list1.typeSchedule ~= list.typeSchedule and 
		  not(list1.typeSchedule=="Commit" and list.typeSchedule == "Revs")) then
			same = false
		else
			for i = 1,#list do
				if list[i] ~= list1[i] then
					same = false
					break
				end
			end
		end
		if not same then
			-- Add the schedule here
			if not task.Schedules then
				task.Schedules = {}
			end
			if not task.Schedules[list.typeSchedule] then
				-- Schedule type does not exist so create it
				task.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}
			end
			-- Schedule type already exists so just add it to the next index
			local newSched = {[0]=list.typeSchedule}
			local str = "WD"
			if list.typeSchedule ~= "Actual" then
				newSched.Updated = todayDate
				str = "DP"
			else
				error("Got Actual schedule type while processing schedule.")
			end
			-- Update the period
			newSched.Period = {[0] = "Period", count = #list}
			for i = 1,#list do
				newSched.Period[i] = {[0] = str, Date = list[i]}
			end
			task.Schedules[list.typeSchedule][list.index] = newSched
			task.Schedules[list.typeSchedule].count = list.index
		end
	end		-- if list ends here
	task.Planning = nil	
	if Karm.GUI.taskTree.taskList then
		for i = 1,#Karm.GUI.taskTree.taskList do
			if Karm.GUI.taskTree.taskList[i] == task then
				-- Remove this one
				for j = i,#Karm.GUI.taskTree.taskList - 1 do
					Karm.GUI.taskTree.taskList[j] = Karm.GUI.taskTree.taskList[j + 1]
				end
				Karm.GUI.taskTree.taskList[#Karm.GUI.taskTree.taskList] = nil
				break
			end
		end
	end
	-- Check if the task passes the filter now
	local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
	if #taskList == 1 then
		-- It passes the filter so update the task
	    Karm.GUI.taskTree:UpdateNode(task)
		Karm.GUI.taskClicked(task)
		-- Update all the parents as well
		local currNode = Karm.GUI.taskTree.Nodes[task.TaskID]
		while currNode and currNode.Parent do
			currNode = currNode.Parent
			if currNode.Task then
				Karm.GUI.taskTree:UpdateNode(currNode.Task)
			end
		end
    else
    	-- Delete the task node and adjust the hier level of all the sub task hierarchy if any
    	Karm.GUI.taskTree:DeleteSubUpdate(task.TaskID)
    end
    Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
end		-- function Karm.finalizePlanning ends

function Karm.RunFile(file)
	local f,message = loadfile(file)
	if not f then
		wx.wxMessageBox("Error in compilation/loading: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	else
		local stat,message = pcall(f)
		if not stat then
			wx.wxMessageBox("Error Running File: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		end
	end	
end

function Karm.RunScript(script)
	local f,message = loadstring(script)
	if not f then
		wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	else
		local stat,message = pcall(f)
		if not stat then
			wx.wxMessageBox("Error Running Script: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		end
	end	
end

function Karm.Macro(event)
	-- Get the macro details
	local frame = wx.wxFrame(Karm.GUI.frame, wx.wxID_ANY, "Enter Macro Details", wx.wxDefaultPosition,wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
	local MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)
		local ScriptPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local ScriptPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local InsLabel = wx.wxStaticText(ScriptPanel, wx.wxID_ANY, "Enter Script here:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
			ScriptPanelSizer:Add(InsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local ScriptBox = wx.wxTextCtrl(ScriptPanel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)
			ScriptPanelSizer:Add(ScriptBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local scriptButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local CompileButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Test Compile", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local RunButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Run", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local CancelButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			
			scriptButtonSizer:Add(CompileButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			scriptButtonSizer:Add(RunButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			scriptButtonSizer:Add(CancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ScriptPanelSizer:Add(scriptButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		ScriptPanel:SetSizer(ScriptPanelSizer)
		ScriptPanelSizer:SetSizeHints(ScriptPanel)
	MainBook:AddPage(ScriptPanel, "Run Code")
		local FilePanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local FilePanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local FileInsLabel = wx.wxStaticText(FilePanel, wx.wxID_ANY, "Select Lua script file:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
			FilePanelSizer:Add(FileInsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local fileBrowseSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local FileBox = wx.wxTextCtrl(FilePanel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize)
			fileBrowseSizer:Add(FileBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local BrowseButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Browse...", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			fileBrowseSizer:Add(BrowseButton,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			FilePanelSizer:Add(fileBrowseSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local fileButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local FileCompileButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Test Compile", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local FileRunButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Run", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local FileCancelButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			
			fileButtonSizer:Add(FileCompileButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			fileButtonSizer:Add(FileRunButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			fileButtonSizer:Add(FileCancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			FilePanelSizer:Add(fileButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		FilePanel:SetSizer(FilePanelSizer)
		FilePanelSizer:SetSizeHints(FilePanel)
	MainBook:AddPage(FilePanel, "Run File")
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	
	-- Events
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			frame:Close()
		end		
	)
	
	FileCancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			frame:Close()
		end		
	)

	RunButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadstring(ScriptBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				frame:Close()
				Karm.RunScript(ScriptBox:GetValue())
			end
		end		
	)

	FileRunButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the File
			local f,message = loadfile(FileBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation/loading: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				frame:Close()
				Karm.RunFile(FileBox:GetValue())
			end
		end		
	)

	BrowseButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
		    local fileDialog = wx.wxFileDialog(frame, "Select file",
		                                       "",
		                                       "",
		                                       "Lua files (*.lua)|*.lua|wxLua files (*.wlua)|*.wlua|All files (*)|*",
		                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
		    if fileDialog:ShowModal() == wx.wxID_OK then
		    	FileBox:SetValue(fileDialog:GetPath())
		    end
		    fileDialog:Destroy()
		end		
	)

	CompileButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadstring(ScriptBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				wx.wxMessageBox("Compilation successful","Success", wx.wxOK + wx.wxCENTRE, frame)			
			end
		end		
	)

	FileCompileButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadfile(FileBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				wx.wxMessageBox("Compilation successful","Success", wx.wxOK + wx.wxCENTRE, frame)			
			end
		end		
	)

	frame:SetSizer(MainSizer)
	frame:Layout()
	frame:Show(true)
end


function Karm.main()
    Karm.GUI.frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm",
                        wx.wxDefaultPosition, wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH),
                        wx.wxDEFAULT_FRAME_STYLE + wx.wxWANTS_CHARS)

	--Toolbar buttons plan 5/10/2012
	-- Open - open native saved data spore
	-- Save - Save everything
	-- Delete Task
	-- Set Filter
	-- Edit Task
	-- New Child
	-- New Next Sibling
	-- New Previous Sibling
	Karm.GUI.ID_LOAD_XML = Karm.NewID()
	Karm.GUI.ID_LOAD = Karm.NewID()
	Karm.GUI.ID_UNLOAD = Karm.NewID()
	Karm.GUI.ID_SAVEALL = Karm.NewID()
	Karm.GUI.ID_SAVECURR = Karm.NewID()
	Karm.GUI.ID_SET_FILTER = Karm.NewID()
	Karm.GUI.ID_NEW_SUB_TASK = Karm.NewID()
	Karm.GUI.ID_NEW_PREV_TASK = Karm.NewID()
	Karm.GUI.ID_NEW_NEXT_TASK = Karm.NewID()
	Karm.GUI.ID_EDIT_TASK = Karm.NewID()
	Karm.GUI.ID_DEL_TASK = Karm.NewID()
	Karm.GUI.ID_MOVE_UNDER = Karm.NewID()
	Karm.GUI.ID_MOVE_ABOVE = Karm.NewID()
	Karm.GUI.ID_MOVE_BELOW = Karm.NewID()
	Karm.GUI.ID_COPY_UNDER = Karm.NewID()
	Karm.GUI.ID_COPY_ABOVE = Karm.NewID()
	Karm.GUI.ID_COPY_BELOW = Karm.NewID()
	Karm.GUI.ID_LUA_MACRO = Karm.NewID()
	
	local bM
	Karm.GUI.toolbar = Karm.GUI.frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
	local toolBmpSize = Karm.GUI.toolbar:GetToolBitmapSize()
	bM = wx.wxImage("images/load_xml.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_LOAD_XML, "Load XML", wx.wxBitmap(bM), "Load XML Spore from Disk")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_LOAD, "Load", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DIR_UP, wx.wxART_MENU, toolBmpSize), "Load Spore from Disk")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_UNLOAD, "Unload", wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER, wx.wxART_MENU, toolBmpSize), "Unload current spore")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_SAVEALL, "Save All", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize), "Save All Spores to Disk")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_SAVECURR, "Save Current", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_MENU, toolBmpSize), "Save current spore to disk")
	Karm.GUI.toolbar:AddSeparator()
	bM = wx.wxImage("images/filter.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_SET_FILTER, "Set Filter", wx.wxBitmap(bM),   "Set Filter Criteria")
	bM = wx.wxImage("images/new_under.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_NEW_SUB_TASK, "Create Subtask", wx.wxBitmap(bM),   "Creat Sub-task")
	bM = wx.wxImage("images/new_below.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_NEW_NEXT_TASK, "Create Next Task", wx.wxBitmap(bM),   "Creat  Next task")
	bM = wx.wxImage("images/new_above.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_NEW_PREV_TASK, "Create Previous Task", wx.wxBitmap(bM),   "Creat Previous task")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_EDIT_TASK, "Edit Task", wx.wxArtProvider.GetBitmap(wx.wxART_REPORT_VIEW, wx.wxART_MENU, toolBmpSize),   "Edit Task")
	bM = wx.wxImage("images/delete.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_DEL_TASK, "Delete Task", wx.wxBitmap(bM),   "Delete Task")
	bM = wx.wxImage("images/move_under.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_MOVE_UNDER, "Move Under", wx.wxBitmap(bM),   "Move Task Under...", wx.wxITEM_CHECK)
	bM = wx.wxImage("images/move_above.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_MOVE_ABOVE, "Move Above", wx.wxBitmap(bM),   "Move task above...", wx.wxITEM_CHECK)
	bM = wx.wxImage("images/move_below.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_MOVE_BELOW, "Move Below", wx.wxBitmap(bM),   "Move task below...", wx.wxITEM_CHECK)
	Karm.GUI.toolbar:AddSeparator()
	bM = wx.wxImage("images/copy_under.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_COPY_UNDER, "Copy Under", wx.wxBitmap(bM), "Copy Task Under...", wx.wxITEM_CHECK)
	bM = wx.wxImage("images/copy_above.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_COPY_ABOVE, "Copy Above", wx.wxBitmap(bM), "Copy Task Above...", wx.wxITEM_CHECK)
	bM = wx.wxImage("images/copy_below.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_COPY_BELOW, "Copy Below", wx.wxBitmap(bM), "Copy Task Below...", wx.wxITEM_CHECK)
	Karm.GUI.toolbar:AddSeparator()
	bM = wx.wxImage("images/lua_macro.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_LUA_MACRO, "Run Lua Macro", wx.wxBitmap(bM), "Run Lua Macro...")
	Karm.GUI.toolbar:Realize()

	-- Create status Bar in the window
    Karm.GUI.statusBar = Karm.GUI.frame:CreateStatusBar(2)
    -- Text for the 1st field in the status bar
    Karm.GUI.frame:SetStatusText("Welcome to Karm", 0)
    Karm.GUI.frame:SetStatusBarPane(-1)
    -- text for the second field in the status bar
    --Karm.GUI.frame:SetStatusText("Test", 1)
    -- Set the width of the second field to 25% of the whole window
    local widths = {}
    widths[1]=-3
    widths[2] = -1
    Karm.GUI.frame:SetStatusWidths(widths)
    Karm.GUI.defaultColor.Red = Karm.GUI.statusBar:GetBackgroundColour():Red()
    Karm.GUI.defaultColor.Green = Karm.GUI.statusBar:GetBackgroundColour():Green()
    Karm.GUI.defaultColor.Blue = Karm.GUI.statusBar:GetBackgroundColour():Blue()
    
    local getMenu
    getMenu = function(menuTable)
		local newMenu = wx.wxMenu()    
		for j = 1,#menuTable do
			if menuTable[j].Text and menuTable[j].HelpText and (menuTable[j].Code or menuTable[j].File) then
				local ID = Karm.NewID()
				newMenu:Append(ID,menuTable[j].Text,menuTable[j].HelpText, menuTable[j].ItemKind or wx.wxITEM_NORMAL)
				-- Connect the event for this
				Karm.GUI.frame:Connect(ID, wx.wxEVT_COMMAND_MENU_SELECTED,Karm.GUI.menuEventHandlerFunction(ID,menuTable[j].Code,menuTable[j].File))
			elseif menuTable[j].Text and menuTable[j].Menu then
				newMenu:Append(wx.wxID_ANY,menuTable[j].Text,getMenu(menuTable[j].Menu))
			end
		end
		return newMenu
    end

    -- create the menubar and attach it
    Karm.GUI.menuBar = wx.wxMenuBar()
	for i = 1,#Karm.GUI.MainMenu do
		if Karm.GUI.MainMenu[i].Text and Karm.GUI.MainMenu[i].Menu then
			Karm.GUI.menuBar:Append(getMenu(Karm.GUI.MainMenu[i].Menu),Karm.GUI.MainMenu[i].Text)
		end
	end    
--    local fileMenu = wx.wxMenu()
--    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")
--    local helpMenu = wx.wxMenu()
--    helpMenu:Append(wx.wxID_ABOUT, "&About", "About Karm")
--
--    Karm.GUI.menuBar:Append(fileMenu, "&File")
--    Karm.GUI.menuBar:Append(helpMenu, "&Help")
	-- MENU COMMANDS
    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    Karm.GUI.frame:Connect(wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW,
        function (event)
        	local count = 0 
			local sporeList = ""
			for k,v in pairs(Karm.Globals.unsavedSpores) do 
				count = count + 1 
				sporeList = sporeList..Karm.Globals.unsavedSpores[k].."\n"
			end 
			local confirm, response 
			if count > 0 then 
				confirm = wx.wxMessageDialog(Karm.GUI.frame,"The following spores:\n"..sporeList.." have unsaved changes. Are you sure you want to exit and loose all changes?", "Loose all changes?", wx.wxYES_NO + wx.wxNO_DEFAULT) 
				response = confirm:ShowModal() 
			else 
				response = wx.wxID_YES 
			end 
			if response == wx.wxID_YES then 
				Karm.GUI.frame:Destroy() 
			end
        end )
--
--    -- connect the selection event of the about menu item
--    Karm.GUI.frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
--        function (event)
--            wx.wxMessageBox('Karm is the Task and Project management application for everybody.\n'..
--                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
--                            "About Karm",
--                            wx.wxOK + wx.wxICON_INFORMATION,
--                            frame)
--        end )

    Karm.GUI.frame:SetMenuBar(Karm.GUI.menuBar)
	Karm.GUI.vertSplitWin = wx.wxSplitterWindow(Karm.GUI.frame, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH), wx.wxSP_3D, "Main Vertical Splitter")
	Karm.GUI.vertSplitWin:SetMinimumPaneSize(10)
	
	Karm.GUI.taskTree = Karm.GUI.newTreeGantt(Karm.GUI.vertSplitWin)
	
	-- Panel to contain the task details and filter criteria text boxes
	local detailsPanel = wx.wxPanel(Karm.GUI.vertSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
							wx.wxDefaultSize, wx.wxTAB_TRAVERSAL, "Task Details Parent Panel")
	-- Main sizer in the detailsPanel containing everything
	local boxSizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	-- Static Box sizer to place the text boxes horizontally (Note: This sizer displays a border and some text on the top)
	local staticBoxSizer1 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Task Details")
	
	-- Task Details text box
	Karm.GUI.taskDetails = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Task Selected", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Details Box")
	staticBoxSizer1:Add(Karm.GUI.taskDetails, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer1:Add(staticBoxSizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	-- Box sizer on the right size to place the Criteria text box and above that the sizer containing the date picker control
	--   to set the dates displayed in the Gantt Grid
	local boxSizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
	-- Sizer inside box sizer2 containing the date picker controls
	local boxSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	Karm.GUI.dateStartPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local month = wx.wxDateSpan(0,1,0,0)
	Karm.GUI.dateFinPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,startDate:Add(month), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
	boxSizer3:Add(Karm.GUI.dateStartPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer3:Add(Karm.GUI.dateFinPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer2:Add(boxSizer3,0, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	local staticBoxSizer2 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Filter Criteria")
	Karm.GUI.taskFilter = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Filter", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Filter Criteria")
	staticBoxSizer2:Add(Karm.GUI.taskFilter, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer2:Add(staticBoxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer1:Add(boxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	detailsPanel:SetSizer(boxSizer1)
	boxSizer1:Fit(detailsPanel)
	boxSizer1:SetSizeHints(detailsPanel)
	Karm.GUI.vertSplitWin:SplitHorizontally(Karm.GUI.taskTree.horSplitWin, detailsPanel)
	Karm.GUI.vertSplitWin:SetSashPosition(0.7*Karm.GUI.initFrameH)

	-- ********************EVENTS***********************************************************************
	-- Date Picker Events
	Karm.GUI.dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,Karm.GUI.dateRangeChangeEvent)
	Karm.GUI.dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,Karm.GUI.dateRangeChangeEvent)
	
	-- Frame resize event
	Karm.GUI.frame:Connect(wx.wxEVT_SIZE, Karm.GUI.frameResize)
	
	-- Task Details click event
	Karm.GUI.taskDetails:Connect(wx.wxEVT_LEFT_DOWN,function(event) print(menuItems) end)
	
	-- Toolbar button events
	Karm.GUI.frame:Connect(Karm.GUI.ID_LOAD_XML,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.loadXML)
	Karm.GUI.frame:Connect(Karm.GUI.ID_SET_FILTER,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.SetFilter)
	Karm.GUI.frame:Connect(Karm.GUI.ID_NEW_SUB_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.NewTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_NEW_NEXT_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.NewTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_NEW_PREV_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.NewTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_EDIT_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.EditTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_DEL_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.DeleteTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_MOVE_UNDER,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.MoveTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_MOVE_ABOVE,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.MoveTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_MOVE_BELOW,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.MoveTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_COPY_UNDER,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.CopyTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_COPY_ABOVE,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.CopyTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_COPY_BELOW,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.CopyTaskToggle)
	
	Karm.GUI.frame:Connect(Karm.GUI.ID_SAVECURR,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.SaveCurrSpore)
	Karm.GUI.frame:Connect(Karm.GUI.ID_LOAD,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.openKarmSpore)
	Karm.GUI.frame:Connect(Karm.GUI.ID_UNLOAD,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.unloadSpore)
	Karm.GUI.frame:Connect(Karm.GUI.ID_SAVEALL,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.SaveAllSpores)
	
	Karm.GUI.frame:Connect(Karm.GUI.ID_LUA_MACRO,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.Macro)

    -- Task selection in task tree
    Karm.GUI.taskTree:associateEventFunc({cellClickCallBack = Karm.GUI.taskClicked})
    -- *******************EVENTS FINISHED***************************************************************
    Karm.GUI.frame:Layout() -- help sizing the windows before being shown
    Karm.GUI.dateRangeChange()	-- To create the colums for the current date range in the GanttGrid

    Karm.GUI.taskTree:layout()
    
    -- Fill the task tree now
    Karm.GUI.fillTaskTree()
		
    wx.wxGetApp():SetTopWindow(Karm.GUI.frame)
    
	-- Key Press events
	--connectKeyUpEvent(Karm.GUI.frame)

	-- Get the user ID
    Karm.GUI.frame:Show(true)
	if not Karm.Globals.User then
		local user = ""
		while user == "" do
			user = wx.wxGetTextFromUser("Enter the user ID", "User ID", "")
		end
		Karm.Globals.User = user
	end
    Karm.GUI.frame:SetTitle("Karm ("..Karm.Globals.User..")")
end

function Karm.Initialize()
	-- Show the Splash Screen
	wx.wxInitAllImageHandlers()
	local splash = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm", wx.wxDefaultPosition, wx.wxSize(400, 300),
                        wx.wxSTAY_ON_TOP + wx.wxFRAME_NO_TASKBAR)
    local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
    local textBox = wx.wxTextCtrl(splash, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_CENTRE + wx.wxBORDER_NONE + wx.wxTE_READONLY)
    local dc = wx.wxPaintDC(textBox)
    local wid,height
    textBox:SetFont(wx.wxFont(30, wx.wxFONTFAMILY_SWISS, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD))
    wid,height = dc:GetTextExtent("Karm",wx.wxFont(30, wx.wxFONTFAMILY_ROMAN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD) )
    local textAttr = wx.wxTextAttr()
    textBox:WriteText("Karm")
    sizer:Add(textBox, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
    textBox = wx.wxTextCtrl(splash, wx.wxID_ANY, "Version: "..Karm.Globals.KARM_VERSION, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_CENTRE + wx.wxBORDER_NONE + wx.wxTE_READONLY)
    sizer:Add(textBox, 0, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
    local panel = wx.wxPanel(splash, wx.wxID_ANY)
	local image = wx.wxImage("images/SplashImage.bmp",wx.wxBITMAP_TYPE_BMP)
	image = image:Scale(100,100)
    sizer:Add(panel, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
    panel:Connect(wx.wxEVT_PAINT,function(event)
		    local cdc = wx.wxPaintDC(event:GetEventObject():DynamicCast("wxWindow"))
		    cdc:DrawBitmap(wx.wxBitmap(image),150,0,false)
		    cdc:delete()
	    end
	)
    splash:SetSizer(sizer)
    splash:Centre()
    splash:Layout()
    splash:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    splash:Show(true)
    local timer = wx.wxTimer(splash)
    splash:Connect(wx.wxEVT_TIMER,function(event)
    							splash:Close()
    							timer:Stop()
								Karm.main()
    						end)
    timer:Start(3000, true)
    
	local configFile = "KarmConfig.lua"
	local f=io.open(configFile,"r")
	if f~=nil then 
		io.close(f) 
		-- load the configuration file
		dofile(configFile)
	end
	-- Load all the XML spores
	local count = 1
	Karm.SporeData[0] = 0
	-- print(Spores[count])
	if Karm.Spores then
		while Karm.Spores[count] do
			if Karm.Spores[count].type == "XML" then
				-- XML file
				Karm.SporeData[Karm.Spores[count].file] = Karm.XML2Data(xml.load(Karm.Spores[count].file), Karm.Spores[count].file)
				Karm.SporeData[Karm.Spores[count].file].Modified = true
				Karm.SporeData[0] = Karm.SporeData[0] + 1
			else
				-- Normal Karm File
				local result,message = pcall(Karm.loadKarmSpore,Karm.Spores[count].file, {onlyData=true})
			end
			count = count + 1
		end
	end
end

-- Do all the initial Configuration and Initialization
Karm.Initialize()

--main()

-- refreshTree()
-- fillDummyData()

-- updateTree(Karm.SporeData)


-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()