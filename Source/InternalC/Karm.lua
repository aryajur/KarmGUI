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
nodeForeColor = {Red=0,Green=0,Blue=0}
nodeBackColor = {Red=255,Green=255,Blue=255}
noScheduleColor = {Red=170,Green=170,Blue=170}
ScheduleColor = {Red=143,Green=62,Blue=215}
emptyDayColor = {Red=255,Green=255,Blue=255}
sunDayOffset = {Red = 50, Green=50, Blue = 50}
-- Task status colors

setfenv(1,_G)

-- Global Declarations
Globals = {
	ROOTKEY = "T0",
	PriorityList = {'1','2','3','4','5','6','7','8','9'},
	StatusList = {'Not Started','On Track','Behind','Done','Obsolete'},
	NoDateStr = "__NO_DATE__",
	NoTagStr = "__NO_TAG__",
	NoAccessIDStr = "__NO_ACCESS__",
	NoCatStr = "__NO_CAT__",
	NoSubCatStr = "__NO_SUBCAT__",
	NoPriStr = "__NO_PRI__",
	__DEBUG = true,		-- For debug mode
	PlanningMode = false	-- Flag to indicate Schedule Planning mode is on.
}

-- Generate a unique new wxWindowID
local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
function NewID()
    ID_IDCOUNTER = ID_IDCOUNTER + 1
    return ID_IDCOUNTER
end

-- Karm files
require("Filter")
require("DataHandler")
GUI.FilterForm = require("FilterForm")		-- Containing all Filter Form GUI code
GUI.TaskForm = require("TaskForm")		-- Containing all Task Form GUI code

require("TestFuncs")		-- Containing all testing functions not used in final deployment

do
	local IDMap = {}	-- Map from wxID to object (used to handle events)
	-- Metatable to define a node object's behaviour
	local nodeMeta = {__metatable = "Hidden, Do not change!"}
	local taskTreeINT = {__metatable = "Hidden, Do not change!"} 
	
	-- Function References
	local onScrollTree, onScrollGantt, labelClick, cellClick, horSashAdjust, widgetResize, refreshGantt, dispTask, dispGantt
	local cellClickCallBack, ganttCellClick, ganttLabelClick

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
	
	local function associateEventFunc(taskTree,funcTable)
		if funcTable.cellClickCallBack == 0 then
			taskTreeINT[taskTree].cellClickCallBack = nil
		else
			taskTreeINT[taskTree].cellClickCallBack = funcTable.cellClickCallBack
		end
	end

	local function dateRangeChange(o,startDate,finDate)
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
			taskTreeINT[o].ganttGrid:SetColLabelValue(count,string.sub(toXMLDate(currDate:Format("%m/%d/%Y")),-2,-1)..
			    string.sub(getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))),1,1))
			taskTreeINT[o].ganttGrid:AutoSizeColumn(count)
			--taskTreeINT[o].ganttGrid:SetColLabelValue(count,string.sub(toXMLDate(currDate:Format("%m/%d/%Y")),-5,-1))
			currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
			count = count + 1
		end
		taskTreeINT[o].startDate = startDate:Subtract(wx.wxDateSpan(0,0,0,count))
		taskTreeINT[o].finDate = finDate		
		refreshGantt(o)
	end
	
	local function layout(taskTree)
		oTree = taskTreeINT[taskTree]
		oTree.treeGrid:AutoSizeColumn(0)
	    oTree.treeGrid:SetColSize(1,oTree.horSplitWin:GetSashPosition()-oTree.treeGrid:GetColSize(0)-oTree.treeGrid:GetRowLabelSize(0))	
	end
	
	local function  enablePlanningMode(taskTree, taskList)
		oTree = taskTreeINT[taskTree]
		oTree.Planning = true
		if not oTree.taskList then
			oTree.taskList = {}
		end
		local count = 1
		for i = 1,#taskList do
			oTree.taskList[count] = taskList[i] 
			if oTree.Nodes[taskList[i].TaskID]:MakeVisible() then
				count = count + 1
				-- Copy over the latest schedule to the planning period
				local dateList = getLatestScheduleDates(taskList[i])
				if dateList then
					togglePlanningType(taskList[i])
					taskList[i].Planning.Period = {[0]="Period",count=0}
					for j=1,#dateList do
						taskList[i].Planning.Period[j] = {[0]="DP",Date=dateList[j]}
						taskList[i].Planning.Period.count = taskList[i].Planning.Period.count + 1
					end
				end
				dispGantt(taskTree,oTree.Nodes[taskList[i].TaskID].Row,false,oTree.Nodes[taskList[i].TaskID])
			end
		end
		oTree.taskList[count] = nil
	end
	
	local function getPlanningTasks(taskTree)
		oTree = taskTreeINT[taskTree]
		if not oTree.Planning then
			return nil
		else
			return oTree.taskList
		end
	end
	
	local function getSelectedTask(taskTree)
		oTree = taskTreeINT[taskTree]
		return oTree.Selected
	end
	
	function newGUITreeGantt(parent,noTaskTree)
		local taskTree = {}	-- Main object
		-- Main table to store the task tree that is on display
		taskTreeINT[taskTree] = {Nodes = {}, Roots = {}, update = true, nodeCount = 0, actionQ = {}, Planning = nil, taskList = nil, Selected = {},
		   dateRangeChange = dateRangeChange, layout = layout, associateEventFunc = associateEventFunc, enablePlanningMode = enablePlanningMode,
		   getPlanningTasks = getPlanningTasks, getSelectedTask = getSelectedTask}
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
		local ID = NewID()
		oTree.horSplitWin = wx.wxSplitterWindow(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxSP_3D, "Task Splitter")
		IDMap[ID] = taskTree
		-- wx.wxSize(GUI.initFrameW, 0.7*GUI.initFrameH)
		if not noTaskTree then
			oTree.horSplitWin:SetMinimumPaneSize(10)
		end

		ID = NewID()		
		oTree.treeGrid = wx.wxGrid(oTree.horSplitWin, ID, wx.wxDefaultPosition, 
						wx.wxDefaultSize, 0, "Task Tree Grid")
		IDMap[ID] = taskTree
	    oTree.treeGrid:CreateGrid(1,2)
	    oTree.treeGrid:SetColFormatBool(0)
	    oTree.treeGrid:SetRowLabelSize(15)
	    oTree.treeGrid:SetColLabelValue(0," ")
	    oTree.treeGrid:SetColLabelValue(1,"Tasks")
	    --GUI.treeGrid:SetCellHighlightPenWidth(0)
	    oTree.treeGrid:EnableGridLines(false)
	
		ID = NewID()
		oTree.ganttGrid = wx.wxGrid(oTree.horSplitWin, ID, wx.wxDefaultPosition, 
							wx.wxDefaultSize, 0, "Gantt Chart Grid")
		IDMap[ID] = taskTree
	    oTree.ganttGrid:CreateGrid(1,1)
	    oTree.ganttGrid:EnableGridLines(false)
	    -- GUI.ganttGrid:SetRowLabelSize(0)
	
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
		
		-- The TreeGrid label click event
		oTree.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,labelClick)
		--GUI.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,GUI.taskDblClick)
		
		-- The GanttGrid label click event
		oTree.ganttGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,ganttLabelClick)

		-- Gantt Grid Cell left click event
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,ganttCellClick)
		
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
							if oTree.Selected[oTree.Selected.Latest].Row then
								oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
							else
								-- The selected node is not visible anymore
								currNode = oTree.Selected[oTree.Selected.Latest].Parent
								while not currNode.Row do
									currNode = currNode.Parent
								end
								oTree.treeGrid:SetGridCursor(currNode.Row-1,1)
							end
						end
					end
					-- Expanded was true and now making it false
					oNode.Expanded = nil
				else
					oTree.actionQ[#oTree.actionQ + 1] = "taskTreeINT[tab].Nodes['"..oNode.Key.."'].Expanded = nil"
				end		-- if oTree.update then ends
			elseif not oNode.Expanded and val then
				-- Check if updates are enabled
				if oTree.update then
					if oNode.Row then
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
							if #oTree.Selected > 0 then
								oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
							end
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
								nextNode.Expanded = nil
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
					oTree.actionQ[#oTree.actionQ + 1] = "taskTreeINT[tab].Nodes['"..oNode.Key.."'].Expanded = true"
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
		else
			oNode[key] = val
		end		-- if key == ?? ends here
	end		-- function nodeMeta.__newindex(tab,key,val) ends

	function taskTreeINT.__index(tab,key)
		-- function to catch all accesses to taskTree
		return taskTreeINT[tab][key]
	end
	
	function taskTreeINT.__newindex(tab,key,val)
		-- function to catch all setting commands to GUI.taskTree
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
		if taskNode.Children > 0 then
			taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,1,string.rep(" ",hierLevel*4)..taskNode.Title)
			if taskNode.Expanded then
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1,"-")
			else
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1,"+")
			end
		else
			taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,1,string.rep(" ",hierLevel*4)..taskNode.Title)
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
			taskTreeINT[taskTree].treeGrid.SetCellBackgroundColour(row-1,1,wx.wxColour(taskNode.BackColor.Red,taskNode.BackColor.Green,taskNode.BackColor.Blue))
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
		local startDay = toXMLDate(taskTreeINT[taskTree].startDate:Format("%m/%d/%Y"))
		local finDay = toXMLDate(taskTreeINT[taskTree].finDate:Format("%m/%d/%Y"))
		local days = taskTreeINT[taskTree].ganttGrid:GetNumberCols()
		--print(getWeekDay(startDay))
		if not taskNode.Task then
			-- No task associated with the node so color the cells to show no schedule
			taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"X")
			local currDate = XMLDate2wxDateTime(startDay)
			for i = 1,days do
				--print(currDate:Format("%m/%d/%Y"),getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))))
				if getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
					local newColor = {Red=GUI.noScheduleColor.Red - GUI.sunDayOffset.Red,Green=GUI.noScheduleColor.Green - GUI.sunDayOffset.Green,
					Blue=GUI.noScheduleColor.Blue-GUI.sunDayOffset.Blue}
					if newColor.Red < 0 then newColor.Red = 0 end
					if newColor.Green < 0 then newColor.Green = 0 end
					if newColor.Blue < 0 then newColor.Blue = 0 end
					taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
				else
					taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.noScheduleColor.Red,
						GUI.noScheduleColor.Green,GUI.noScheduleColor.Blue))
				end
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
			local dateList = getLatestScheduleDates(taskNode.Task,planning)
			if not dateList then
				-- No task associated with the node so color the cells to show no schedule
				if planning then
					taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"(P)X")
				else
					taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"X")
				end
				local currDate = XMLDate2wxDateTime(startDay)
				for i = 1,days do
					if getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
						local newColor = {Red=GUI.noScheduleColor.Red - GUI.sunDayOffset.Red,Green=GUI.noScheduleColor.Green - GUI.sunDayOffset.Green,
						Blue=GUI.noScheduleColor.Blue-GUI.sunDayOffset.Blue}
						if newColor.Red < 0 then newColor.Red = 0 end
						if newColor.Green < 0 then newColor.Green = 0 end
						if newColor.Blue < 0 then newColor.Blue = 0 end
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
					else
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.noScheduleColor.Red,
							GUI.noScheduleColor.Green,GUI.noScheduleColor.Blue))
					end
					currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
					taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
				end
			else
				local map
				if planning then
					map = {Estimate="(P)E",Commit = "(P)C", Revs = "(P)R", Actual = "(P)A"}
				else
					map = {Estimate="E",Commit = "C", Revs = "R", Actual = "A"}
				end
				-- Erase the previous schedule on the row
				local currDate = XMLDate2wxDateTime(startDay)
				for i=1,days do
					if getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
						local newColor = {Red=GUI.emptyDayColor.Red - GUI.sunDayOffset.Red,Green=GUI.emptyDayColor.Green - GUI.sunDayOffset.Green,
						Blue=GUI.emptyDayColor.Blue-GUI.sunDayOffset.Blue}
						if newColor.Red < 0 then newColor.Red = 0 end
						if newColor.Green < 0 then newColor.Green = 0 end
						if newColor.Blue < 0 then newColor.Blue = 0 end
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
					else
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.emptyDayColor.Red,
							GUI.emptyDayColor.Green,GUI.emptyDayColor.Blue))
					end
					currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
					taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
				end		
				local before,after
				for i=1,#dateList do
					currDate = XMLDate2wxDateTime(dateList[i])
					if dateList[i]>=startDay and dateList[i]<=finDay then
						-- This date is in range find the column which needs to be highlighted
	--					local range = days
	--					local stepDate = GUI.dateStartPick:GetValue()
	--					stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,math.floor(range/2)))
	--					local col = math.ceil(range/2)
	--					while not stepDate:IsSameDate(currDate) do
	--						if stepDate:IsEarlierThan(currDate) then
	--							-- Select the upper range
	--							range = math.ceil(range/2)
	--							stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,math.floor(range/2)))
	--							col = math.ceil(range/2)
	--						else
	--							-- Select lower range
	--							stepDate = stepDate:Subtract(wx.wxDateSpan(0,0,0,math.floor(range/2)))
	--							range = math.floor(range/2)
	--							stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,math.floor(range/2)))
	--							col = math.floor(range/2)							
	--						end
	--					end
	
						local col = 0					
						local stepDate = XMLDate2wxDateTime(startDay)
						while not stepDate:IsSameDate(currDate) do
							stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
							col = col + 1
						end
						--taskTreeINT[taskTree].startDate:Subtract(wx.wxDateSpan(0,0,0,col))
						if getWeekDay(toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
							local newColor = {Red=GUI.ScheduleColor.Red - GUI.sunDayOffset.Red,Green=GUI.ScheduleColor.Green - GUI.sunDayOffset.Green,
							    Blue=GUI.ScheduleColor.Blue-GUI.sunDayOffset.Blue}
							if newColor.Red < 0 then newColor.Red = 0 end
							if newColor.Green < 0 then newColor.Green = 0 end
							if newColor.Blue < 0 then newColor.Blue = 0 end
							taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
						else
							taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(GUI.ScheduleColor.Red,
								GUI.ScheduleColor.Green,GUI.ScheduleColor.Blue))
						end
						taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,col)
					else
						if dateList[i]<startDay then
							before = true
						end
						if dateList[i]>finDay then
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
	function taskTreeINT.UpdateKeys(taskTree,node)
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
		if nodeMeta[node1].Key:sub(1,#Globals.ROOTKEY)==Globals.ROOTKEY then
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

	-- Updates a node with the key same as the given task's TaskID
	function taskTreeINT.UpdateNode(taskTree,task)
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[task.TaskID]
		
		nodeMeta[node].Task = task
		nodeMeta[node].Title = task.Title

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
			oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
				task.TaskID.."'].Row,false,taskTreeINT[tab].Nodes['"..task.TaskID.."'],"..tostring(hierLevel)..")"
			oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes['"..
				task.TaskID.."'].Row,false,taskTreeINT[tab].Nodes['"..task.TaskID.."'])"				
			oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
		end
	end
	
	function taskTreeINT.DeleteSubUpdate(taskTree,task)
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[task.TaskID]
		local parent = nodeMeta[node].Parent
		-- Expand the node first
		node.Expanded = true
		-- Update the row numbers of all subsequent tasks first
		local key,nextNode = taskTree:nextVisibleNode(task.TaskID)
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
						nodeMeta[nextNode].Key.."'].Row,false,taskTreeINT[tab].Nodes['"..nodeMeta[nextNode].Key.."'],"..tostring(hierLevel)..")"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes['"..
						nodeMeta[nextNode].Key.."'].Row,false,taskTreeINT[tab].Nodes['"..nodeMeta[nextNode].Key.."'])"				
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
		if parent then
			nodeMeta[parent].Children = nodeMeta[parent].Children + nodeMeta[node].Children
			if not nodeMeta[node].Prev and nodeMeta[node].FirstChild then
				nodeMeta[parent].FirstChild = nodeMeta[node].FirstChild
			end
			if not nodeMeta[node].Next and nodeMeta[node].LastChild then
				nodeMeta[parent].LastChild = nodeMeta[node].LastChild
			end
		end

		-- Update the sibling links of the node
		if nodeMeta[node].Prev then
			if nodeMeta[node].FirstChild then
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].FirstChild
				nodeMeta[nodeMeta[node].FirstChild].Prev = nodeMeta[node].Prev
			else
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
			end
		end
		if nodeMeta[node].Next then
			if nodeMeta[node].LastChild then
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].LastChild
				nodeMeta[nodeMeta[node].LastChild].Next = nodeMeta[node].Next
			else
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
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
				if oTree.Selected.Latest > #oTree.Selected then
					oTree.Selected.Lates = #oTree.Selected
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
		                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
			return nil
		end
		-- Check if Relative exist
		if nodeInfo.Relative then
			if not oTree.Nodes[nodeInfo.Relative] then
				-- Relative specified but does not exist
				wx.wxMessageBox("Specified relative does not exist ("..nodeInfo.Relative..") in the task Tree.",
			                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
				return nil
			end
			-- Since relative is specified relation should be specified
			if not nodeInfo.Relation then
				-- Relative specified but Relation not specified
				wx.wxMessageBox("No relation specified for task (".. nodeInfo.Text..").",
			                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
				return nil
			end
		end
		-- Check if Relation if correct
		if nodeInfo.Relation then
			if string.upper(nodeInfo.Relation) ~= "CHILD" and string.upper(nodeInfo.Relation) ~= "NEXT SIBLING" and string.upper(nodeInfo.Relation) ~= "PREV SIBLING" then
				-- Relation specified incorrectly 
				wx.wxMessageBox("Specified relation is not correct ("..nodeInfo.Relation.."). Allowed values are 'Child', 'Next Sibling', 'Prev Sibling'.",
			                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
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
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
						nodeInfo.Key.."'].Row,true,taskTreeINT[tab].Nodes['"..nodeInfo.Key.."'],0)"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes['"..
						nodeInfo.Key.."'].Row,true,taskTreeINT[tab].Nodes['"..nodeInfo.Key.."'])"				
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
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,1,true,taskTreeINT[tab].Nodes['"..
						nodeInfo.Key.."'],0)"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,1,true,taskTreeINT[tab].Nodes['"..
						nodeInfo.Key.."'])"
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
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
							nodeInfo.Key.."'].Row,true,taskTreeINT[tab].Nodes['"..nodeInfo.Key.."'],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
							nodeInfo.Key.."'].Row,true,taskTreeINT[tab].Nodes['"..nodeInfo.Key.."'])"
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
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
							nodeInfo.Key.."'].Row,true,taskTreeINT[tab].Nodes['"..nodeInfo.Key.."'],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
							nodeInfo.Key.."'].Row,true,taskTreeINT[tab].Nodes['"..nodeInfo.Key.."'])"
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
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
							nodeInfo.Key.."'].Row,true,taskTreeINT[tab].Nodes['"..nodeInfo.Key.."'],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
							nodeInfo.Key.."'].Row,true,taskTreeINT[tab].Nodes['"..nodeInfo.Key.."'])"
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
		--event:Skip()
	end
	
	local function ganttLabelClickFunc(event)
		-- Find the row of the click
		local obj = IDMap[event:GetId()]
		if taskTreeINT[obj].Planning then
			local oTree = taskTreeINT[obj]
			local row = event:GetRow()
			local col = event:GetCol()
			if row > -1 then
				for i = 1,#oTree.taskList do
					if oTree.Nodes[oTree.taskList[i].TaskID].Row == row+1 then
						-- This is the task modify/add the planning schedule
						togglePlanningType(oTree.taskList[i])
						dispGanttFunc(obj,row+1,false,oTree.Nodes[oTree.taskList[i].TaskID])
						break
					end
				end
			end		-- if row > -1 then ends
		end		-- if taskTreeINT[obj].Planning then ends
		--event:Skip()
	end

	local function onScrollTreeFunc(obj)
		return function(event)
			oTree = taskTreeINT[obj]
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
	
	
	local function onScrollGanttFunc(obj)
		return function(event)
			event:Skip()
			oTree = taskTreeINT[obj]
			oTree.treeGrid:Scroll(oTree.treeGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.ganttGrid:GetScrollPos(wx.wxVERTICAL))

			local currDate = oTree.startDate
			local finDate = oTree.finDate
			local count = 0
--			local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count))
--			y1 = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count+1),wx.wxGridCellCoords(0,count+1))
--   			GUI.frame:SetStatusText(tostring(y:GetTopLeft():GetX())..","..tostring(y:GetTopLeft():GetY())..","..
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
		--local info = "Sash: "..tostring(GUI.horSplitWin:GetSashPosition()).."\nCol 0: "..tostring(GUI.treeGrid:GetColSize(0)).."\nCol 1 Before: "..tostring(GUI.treeGrid:GetColSize(1))
		local obj = IDMap[event:GetId()]
		oTree = taskTreeINT[obj]
		oTree.treeGrid:SetColMinimalWidth(1,oTree.horSplitWin:GetSashPosition()-oTree.treeGrid:GetColSize(0)-oTree.treeGrid:GetRowLabelSize(0))
		oTree.treeGrid:AutoSizeColumn(1,false)
		--info = info.."\nCol 1 After: "..tostring(GUI.treeGrid:GetColSize(1))
		--GUI.taskDetails:SetValue(info)	
		event:Skip()
	end
	
	local function widgetResizeFunc(event)
		local obj = IDMap[event:GetId()]
		oTree = taskTreeINT[obj]
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
					taskTreeINT[obj].cellClickCallBack(taskNode.Task)
				end
			else
				taskTreeINT[obj].Selected = {}
			end
			taskTreeINT[obj].treeGrid:SetGridCursor(row,col)
		end		
		--taskTreeINT[obj].treeGrid:SelectBlock(row,col,row,col)
		--event:Skip()
	end
	
	local function ganttCellClickFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local row = event:GetRow()
		local col = event:GetCol()
		if taskTreeINT[obj].Planning then
			if row > -1 then
				for i = 1,#oTree.taskList do
					if oTree.Nodes[oTree.taskList[i].TaskID].Row == row+1 then
						-- This is the task modify/add the planning schedule
						local colCount = 0					
						local stepDate = XMLDate2wxDateTime(toXMLDate(taskTreeINT[obj].startDate:Format("%m/%d/%Y")))
						while colCount < col do
							stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
							colCount = colCount + 1
						end
						togglePlanningDate(oTree.taskList[i],toXMLDate(stepDate:Format("%m/%d/%Y")))
						dispGanttFunc(obj,row+1,false,oTree.Nodes[oTree.taskList[i].TaskID])
						break
					end
				end
			end		-- if row > -1 then ends
		end		-- if taskTreeINT[obj].Planning then ends
		oTree.ganttGrid:SetGridCursor(event:GetRow(),event:GetCol())
		cellClickFunc(wx.wxGridEvent(event:GetId(),wx.wxEVT_GRID_CELL_LEFT_CLICK,oTree.treeGrid,event:GetRow(),1))
	end		-- local function ganttCellClickFunc(event) ends
	
	ganttCellClick = ganttCellClickFunc
	ganttLabelClick = ganttLabelClickFunc
	cellClick = cellClickFunc
	widgetResize = widgetResizeFunc
	horSashAdjust = horSashAdjustFunc
	onScrollGantt = onScrollGanttFunc
	onScrollTree = onScrollTreeFunc
	labelClick = labelClickFunc
	
end	-- The custom tree and Gantt widget object for Karm ends here

function Initialize()
	configFile = "KarmConfig.lua"
	local f=io.open(configFile,"r")
	if f~=nil then 
		io.close(f) 
		-- load the configuration file
		dofile(configFile)
	end
	-- Load all the XML spores
	local count = 1
	-- print(Spores[count])
	if Spores then
		while Spores[count] do
			SporeData[Spores[count]] = XML2Data(xml.load(Spores[count]), Spores[count])
			count = count + 1
		end
	end
	SporeData[0] = count - 1
end

function GUI.frameResize(event)
	local winSize = event:GetSize()
	local hei = 0.6*winSize:GetHeight()
	if winSize:GetHeight() - hei > 400 then
		hei = winSize:GetHeight() - 400
	end
	GUI.vertSplitWin:SetSashPosition(hei)
	event:Skip()
end

function GUI.dateRangeChangeEvent(event)
	local startDate = GUI.dateStartPick:GetValue()
	local finDate = GUI.dateFinPick:GetValue()
	GUI.taskTree:dateRangeChange(startDate,finDate)
	event:Skip()
end

function GUI.dateRangeChange()
	-- Clear the GanttGrid
	local startDate = GUI.dateStartPick:GetValue()
	local finDate = GUI.dateFinPick:GetValue()
	GUI.taskTree:dateRangeChange(startDate,finDate)
end

function taskInfoUpdate(task)
	GUI.taskDetails:SetValue(getTaskSummary(task))
end

--****f* Karm/fillTaskTree
-- FUNCTION
-- Function to recreate the task tree based on the global filter criteria from all the loaded spores
--
-- SOURCE
function fillTaskTree()
-- ALGORITHM

	local prevSelect, restorePrev
	local expandedStatus = {}
	GUI.taskTree.update = false		-- stop GUI updates for the time being    
    if GUI.taskTree.nodeCount > 0 then
-- Check if the task Tree has elements then get the current selected nodekey this will be selected again after the tree view is refreshed
        for i,v in GUI.taskTree.tpairs(GUI.taskTree) do
        	if v.Expanded then
        		-- NOTE: i is the same as the TaskID i.e. i == GUI.taskTree.Nodes[i].Task.TaskID
            	expandedStatus[i] = true
            end
            if v.Selected then
                prevSelect = i
            end
        end
        restorePrev = true
    end
    
-- Clear the treeview and add the root element
    GUI.taskTree:Clear()
    GUI.taskTree:AddNode{Key=Globals.ROOTKEY, Text = "Task Spores"}
    GUI.taskTree.Nodes[Globals.ROOTKEY].ForeColor = GUI.nodeForeColor

    if SporeData[0] > 0 then
-- Populate the tree control view
		local count = 0
        for k,v in pairs(SporeData) do
        	if k~=0 then
            -- Get the tasks in the spore
-- Add the spore to the TaskTree
				-- Find the name of the file
				local strVar
        		local intVar1 = -1
				count = count + 1
            	for intVar = #k,1,-1 do
                	if string.sub(k, intVar, intVar) == "." then
                    	intVar1 = intVar
                	end
                	if string.sub(k, intVar, intVar) == "\\" or string.sub(k, intVar, intVar) == "/" then
                    	strVar = string.sub(k, intVar + 1, intVar1-1)
                    	break
                	end
            	end
            	if not strVar then
            		strVar = k
            	end
            	-- Add the spore node
	            GUI.taskTree:AddNode{Relative=Globals.ROOTKEY, Relation="Child", Key=Globals.ROOTKEY..k, Text=strVar, Task = v}
	            GUI.taskTree.Nodes[Globals.ROOTKEY..k].ForeColor = GUI.nodeForeColor
				local taskList = applyFilterHier(Filter, v)
-- Now add the tasks under the spore in the TaskTree
            	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore
	                -- Add the 1st element under the spore
    	            local currNode = GUI.taskTree:AddNode{Relative=Globals.ROOTKEY..k, Relation="Child", Key=taskList[1].TaskID, 
    	            		Text=taskList[1].Title, Task=taskList[1]}
                	currNode.ForeColor = GUI.nodeForeColor
	                for intVar = 2,taskList.count do
	                	local cond1 = currNode.Key ~= Globals.ROOTKEY..k
	                	local cond2 = #taskList[intVar].TaskID > #currNode.Key
	                	local cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                    	while cond1 and not (cond2 and cond3) do
                        	-- Go up the hierarchy
                        	currNode = currNode.Parent
		                	cond1 = currNode.Key ~= Globals.ROOTKEY..k
		                	cond2 = #taskList[intVar].TaskID > #currNode.Key
		                	cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                        end
                    	-- Now currNode has the node which is the right parent
	                    currNode = GUI.taskTree:AddNode{Relative=currNode.Key, Relation="Child", Key=taskList[intVar].TaskID, 
	                    		Text=taskList[intVar].Title, Task = taskList[intVar]}
                    	currNode.ForeColor = nodeColor
                    end
	            end  -- if taskList.count > 0 then ends
			end		-- if k~=0 then ends
-- Repeat for all spores
        end		-- for k,v in pairs(SporeData) do ends
    end  -- if SporeData[0] > 0 then ends
    local selected
    if restorePrev then
-- Update the tree status to before the refresh
        for k,currNode in GUI.taskTree.tpairs(GUI.taskTree) do
            if expandedStatus[currNode.Key] then
                currNode.Expanded = true
			end
        end
        for k,currNode in GUI.taskTree.tvpairs(GUI.taskTree) do
            if currNode.Key == prevSelect then
                currNode.Selected = true
                selected = currNode.Task
            end
        end
    else
 		GUI.taskTree.Nodes[Globals.ROOTKEY].Expanded = true
    end
	GUI.taskTree.update = true		-- Resume the tasktree update    
	-- Update the Filter summary
	if Filter then
		GUI.taskFilter:SetValue(textSummary(Filter))
	else
	    GUI.taskFilter:SetValue("No Filter")
	end
    GUI.taskDetails:SetValue(getTaskSummary(selected))
end
--@@END@@

function SetFilterCallBack(filter)
	GUI.FilterWindowOpen = false
	if filter then
		Filter = filter
		fillTaskTree()
	end
end

function SetFilter(event)
	if not GUI.FilterWindowOpen then
		GUI.FilterForm.filterFormActivate(GUI.frame,SetFilterCallBack)
		GUI.FilterWindowOpen = true
	else
		GUI.FilterForm.frame:SetFocus()
	end
end

-- Relative = relative of this new node (should be a task ID) 
-- Relation = relation of this new node to the Relative. This can be "Child", "Next Sibling", "Prev Sibling" 
function NewTaskCallBack(task)
	if task then
		if GUI.TaskWindowOpen.Spore then
			-- Add child to Spore i.e. Create a new root task in the spore
			-- Add the task to the SporeData
			addTask2Spore(task,SporeData[task.SporeFile])
		else
			-- Normal Hierarchy add
			if GUI.TaskWindowOpen.Relation:upper() == "CHILD" then
				-- Add child
				addTask2Parent(task, task.Parent, SporeData[task.SporeFile])
			elseif GUI.TaskWindowOpen.Relation:upper() == "NEXT SIBLING" then
				-- Add as next sibling
				if not task.Parent then
					-- Task is a root task in a spore
					addTask2Spore(task,SporeData[task.SporeFile])
					-- Now move it to the right place
					bubbleTask(task,GUI.taskTree.Nodes[GUI.TaskWindowOpen.Relative].Task,"AFTER",SporeData[task.SporeFile])
				else
					-- First add as child
					addTask2Parent(task, task.Parent, SporeData[task.SporeFile])
					-- Now move it to the right place
					bubbleTask(task,GUI.taskTree.Nodes[GUI.TaskWindowOpen.Relative].Task,"AFTER")
					-- Now modify the GUI keys
					local currNode = GUI.taskTree.Nodes[GUI.TaskWindowOpen.Relative].Parent.LastChild
					local relative = GUI.taskTree.Nodes[GUI.TaskWindowOpen.Relative]
					while currNode ~= relative do
						GUI.taskTree:UpdateKeys(currNode)
						currNode = currNode.Prev					
					end
				end		-- if not task.Parent then ends here
			else
				-- Add as previous sibling
				if not task.Parent then
					-- Task is a root spore node
					addTask2Spore(task,SporeData[task.SporeFile])
					-- Now move it to the right place
					bubbleTask(task,GUI.taskTree.Nodes[GUI.TaskWindowOpen.Relative].Task,"BEFORE",SporeData[task.SporeFile])
				else
					-- First add as child
					addTask2Parent(task, task.Parent, SporeData[task.SporeFile])
					-- Now move it to the right place
					bubbleTask(task,GUI.taskTree.Nodes[GUI.TaskWindowOpen.Relative].Task,"BEFORE")
					-- Now modify the GUI keys and add it to the UI
					local currNode = GUI.taskTree.Nodes[GUI.TaskWindowOpen.Relative].Parent.LastChild
					local relative = GUI.taskTree.Nodes[GUI.TaskWindowOpen.Relative]
					while currNode ~= relative do
						GUI.taskTree:UpdateKeys(currNode)
						currNode = currNode.Prev					
					end
					-- Move the relative also
					GUI.taskTree:UpdateKeys(currNode)
					-- Since the Relative ID has changed update the ID in TaskWindowOpen here
					GUI.TaskWindowOpen.Relative = currNode.Key
				end		-- if not task.Parent then ends here
			end		-- if GUI.TaskWindowOpen.Relation:upper() == "CHILD" then ends here
		end		-- if GUI.TaskWindowOpen.Spore then ends here
		local taskList = applyFilterList(Filter,{[1]=task})
		if #taskList == 1 then
		    GUI.taskTree:AddNode{Relative=GUI.TaskWindowOpen.Relative, Relation=GUI.TaskWindowOpen.Relation, Key=task.TaskID, Text=task.Title, Task=task}
	    	GUI.taskTree.Nodes[task.TaskID].ForeColor = GUI.nodeForeColor
	    end
    end
	GUI.TaskWindowOpen = false
end

function EditTaskCallBack(task)
	if task then
		-- Replace task into GUI.TaskWindowOpen.Task
		if not GUI.TaskWindowOpen.Task.Parent then
			-- This is a root task in the Spore
			local Spore = SporeData[GUI.TaskWindowOpen.Task.SporeFile]
			for i=1,#Spore do
				if Spore[i] == GUI.TaskWindowOpen.Task then
					Spore[i] = task
					break
				end
			end
		else
			local parentTask = GUI.TaskWindowOpen.Task.Parent
			for i=1,#parentTask.SubTasks do
				if parentTask.SubTasks[i] == GUI.TaskWindowOpen.Task then
					parentTask.SubTasks[i] = task
					break
				end
			end
		end
		-- Update the task in the GUI here
		-- Check if the task passes the filter now
		local taskList = applyFilterList(Filter,{[1]=task})
		if #taskList == 1 then
			-- It passes the filter so update the task
		    GUI.taskTree:UpdateNode(task)
	    else
	    	-- Delete the task and adjust the hier level of all the sub task hierarchy if any
	    	GUI.taskTree:DeleteSubUpdate(task)
	    end
	end
	GUI.TaskWindowOpen = false
end

function EditTask(event)
	if not GUI.TaskWindowOpen then
		-- Get the selected task
		local taskList = GUI.taskTree.Selected
		if #taskList == 0 then
            wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, GUI.frame)
            return
		end			
		if #taskList > 1 then
            wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, GUI.frame)
            return
		end		
		-- Get the new task task ID
		local taskID = taskList[1].Key
		if taskID == Globals.ROOTKEY then
			-- Root node editing requested
			wx.wxMessageBox("Nothing editable in the root node","Root Node Editing", wx.wxOK + wx.wxCENTRE, GUI.frame)
			return
		elseif taskID:sub(1,#Globals.ROOTKEY) == Globals.ROOTKEY then
			-- Spore node editing requested
			wx.wxMessageBox("Nothing editable in the spore node","Spore Node Editing", wx.wxOK + wx.wxCENTRE, GUI.frame)
			return
		else
			-- A normal task editing requested
			GUI.TaskWindowOpen = {Task = taskList[1].Task}
			GUI.TaskForm.taskFormActivate(GUI.frame, EditTaskCallBack,taskList[1].Task)
		end
	end
end

function NewTask(event)
	if not GUI.TaskWindowOpen then
		local taskList = GUI.taskTree.Selected
		if #taskList == 0 then
            wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, GUI.frame)
            return
		end			
		if #taskList > 1 then
            wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, GUI.frame)
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
		if relativeID == Globals.ROOTKEY then
			-- 1. Root node on the tree
			if event:GetId() == GUI.ID_NEW_PREV_TASK or event:GetId() == GUI.ID_NEW_NEXT_TASK then
	            wx.wxMessageBox("A sibling for the root node cannot be created.","Root Node Sibling", wx.wxOK + wx.wxCENTRE, GUI.frame)
	            return
			end						
			-- This is the root so the request is to create a new spore
			local SporeName = wx.wxGetTextFromUser("Enter the Spore File name (Blank to cancel):", "New Spore", "")
			if SporeName == "" then
				return
			end
			SporeData[SporeName] = XML2Data({[0]="Task_Spore"}, SporeName)
			SporeData[SporeName].Modified = "YES"
            GUI.taskTree:AddNode{Relative=Globals.ROOTKEY, Relation="Child", Key=Globals.ROOTKEY..SporeName, Text=SporeName, Task = SporeData[SporeName]}
            GUI.taskTree.Nodes[Globals.ROOTKEY..SporeName].ForeColor = GUI.nodeForeColor
		elseif relativeID:sub(1,#Globals.ROOTKEY) == Globals.ROOTKEY then
			-- 2. Spore Node
			if event:GetId() == GUI.ID_NEW_PREV_TASK or event:GetId() == GUI.ID_NEW_NEXT_TASK then
				local SporeName = wx.wxGetTextFromUser("Enter the Spore File name (Blank to cancel):", "New Spore", "")
				if SporeName == "" then
					return
				end
				SporeData[SporeName] = XML2Data({[0]="Task_Spore"}, SporeName)
				SporeData[SporeName].Modified = "YES"
				if event:GetId() == GUI.ID_NEW_PREV_TASK then
	            	GUI.taskTree:AddNode{Relative=relativeID, Relation="PREV SIBLING", Key=Globals.ROOTKEY..SporeName, Text=SporeName, Task = SporeData[SporeName]}
	            else
	            	GUI.taskTree:AddNode{Relative=relativeID, Relation="NEXT SIBLING", Key=Globals.ROOTKEY..SporeName, Text=SporeName, Task = SporeData[SporeName]}
	            end
	            GUI.taskTree.Nodes[Globals.ROOTKEY..SporeName].ForeColor = GUI.nodeForeColor	
			else
				-- This is a Spore so the request is to create a new root task in the spore
				task.TaskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", "New Task", "")
				if task.TaskID == "" then
					return
				end
				-- Check if the task ID exists in all the loaded spores
				while true do
					local redo = nil
					for k,v in pairs(SporeData) do
	        			if k~=0 then
							local taskList = applyFilterHier({Tasks={[1]={TaskID=task.TaskID}}}, v)
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
				task.SporeFile = string.sub(GUI.taskTree.Nodes[relativeID].Key,#Globals.ROOTKEY+1,-1)
				GUI.TaskWindowOpen = {Spore = true, Relative = relativeID, Relation = "Child"}
				GUI.TaskForm.taskFormActivate(GUI.frame, NewTaskCallBack,task)
			end
		else
			-- 3. Root task node in a Spore
			-- 4. Normal task node
			-- This is a normal task so the request is to create a new task relative to this task
			if event:GetId() == GUI.ID_NEW_SUB_TASK then
				-- Sub task handling is same in both cases
				task.TaskID = getNewChildTaskID(GUI.taskTree.Nodes[relativeID].Task)
				task.Parent = GUI.taskTree.Nodes[relativeID].Task
				GUI.TaskWindowOpen = {Relative = relativeID, Relation = "Child"}
			else
				if not GUI.taskTree.Nodes[relativeID].Task.Parent then
					-- This is a spore root node so will have to ask for the task ID from the user
					task.TaskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", "New Task", "")
					if task.TaskID == "" then
						return
					end
					-- Check if the task ID exists in all the loaded spores
					while true do
						local redo = nil
						for k,v in pairs(SporeData) do
		        			if k~=0 then
								local taskList = applyFilterHier({Tasks={[1]={TaskID=task.TaskID}}}, v)
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
					task.TaskID = getNewChildTaskID(GUI.taskTree.Nodes[relativeID].Task.Parent)
					task.Parent = GUI.taskTree.Nodes[relativeID].Task.Parent
				end
				if event:GetId() == GUI.ID_NEW_PREV_TASK then
					GUI.TaskWindowOpen = {Relative = relativeID, Relation = "PREV SIBLING"}
				else
					GUI.TaskWindowOpen = {Relative = relativeID, Relation = "NEXT SIBLING"}
				end
			end
			task.SporeFile = GUI.taskTree.Nodes[relativeID].Task.SporeFile
			GUI.TaskForm.taskFormActivate(GUI.frame, NewTaskCallBack,task)
		end
		
	else
		GUI.TaskForm.frame:SetFocus()
	end	
end

function loadXML(event)
end

function main()
    GUI.frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm",
                        wx.wxDefaultPosition, wx.wxSize(GUI.initFrameW, GUI.initFrameH),
                        wx.wxDEFAULT_FRAME_STYLE )

	--Toolbar buttons plan 5/10/2012
	-- Open - open native saved data spore
	-- Save - Save everything
	-- Delete Task
	-- Set Filter
	-- Edit Task
	-- New Child
	-- New Next Sibling
	-- New Previous Sibling
	GUI.ID_LOAD = NewID()
	GUI.ID_UNLOAD = NewID()
	GUI.ID_SAVEALL = NewID()
	GUI.ID_SAVECURR = NewID()
	GUI.ID_SET_FILTER = NewID()
	GUI.ID_NEW_SUB_TASK = NewID()
	GUI.ID_NEW_PREV_TASK = NewID()
	GUI.ID_NEW_NEXT_TASK = NewID()
	GUI.ID_EDIT_TASK = NewID()
	GUI.ID_DEL_TASK = NewID()
	GUI.ID_MOVE_UNDER = NewID()
	GUI.ID_MOVE_ABOVE = NewID()
	GUI.ID_MOVE_BELOW = NewID()
	GUI.ID_REPORT = NewID()
	
	local bM = wx.wxImage("images/LoadXML.gif",wx.wxBITMAP_TYPE_GIF)
	
	local toolBar = GUI.frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
	local toolBmpSize = toolBar:GetToolBitmapSize()
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	toolBar:AddTool(GUI.ID_LOAD, "Load", wx.wxBitmap(bM), "Load Spore from Disk")
	--toolBar:AddTool(GUI.ID_LOAD, "Load", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DIR_UP, wx.wxART_MENU, toolBmpSize), "Load Spore from Disk")
	toolBar:AddTool(GUI.ID_UNLOAD, "Unload", wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER, wx.wxART_MENU, toolBmpSize), "Unload current spore")
	toolBar:AddTool(GUI.ID_SAVEALL, "Save All", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize), "Save All Spores to Disk")
	toolBar:AddTool(GUI.ID_SAVECURR, "Save Current", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_MENU, toolBmpSize), "Save current spore to disk")
	toolBar:AddSeparator()
	toolBar:AddTool(GUI.ID_SET_FILTER, "Set Filter", wx.wxArtProvider.GetBitmap(wx.wxART_HELP_SIDE_PANEL, wx.wxART_MENU, toolBmpSize),   "Set Filter Criteria")
	toolBar:AddTool(GUI.ID_NEW_SUB_TASK, "Create Subtask", wx.wxArtProvider.GetBitmap(wx.wxART_ADD_BOOKMARK, wx.wxART_MENU, toolBmpSize),   "Creat Sub-task")
	toolBar:AddTool(GUI.ID_NEW_NEXT_TASK, "Create Next Task", wx.wxArtProvider.GetBitmap(wx.wxART_ADD_BOOKMARK, wx.wxART_MENU, toolBmpSize),   "Creat  Next task")
	toolBar:AddTool(GUI.ID_NEW_PREV_TASK, "Create Previous Task", wx.wxArtProvider.GetBitmap(wx.wxART_ADD_BOOKMARK, wx.wxART_MENU, toolBmpSize),   "Creat Previous task")
	toolBar:AddTool(GUI.ID_EDIT_TASK, "Edit Task", wx.wxArtProvider.GetBitmap(wx.wxART_REPORT_VIEW, wx.wxART_MENU, toolBmpSize),   "Edit Task")
	toolBar:AddTool(GUI.ID_DEL_TASK, "Delete Task", wx.wxArtProvider.GetBitmap(wx.wxART_CROSS_MARK, wx.wxART_MENU, toolBmpSize),   "Delete Task")
	toolBar:AddTool(GUI.ID_MOVE_UNDER, "Move Under", wx.wxArtProvider.GetBitmap(wx.wxART_GO_FORWARD, wx.wxART_MENU, toolBmpSize),   "Move Task Under...")
	toolBar:AddTool(GUI.ID_MOVE_ABOVE, "Move Above", wx.wxArtProvider.GetBitmap(wx.wxART_GO_UP, wx.wxART_MENU, toolBmpSize),   "Move task above...")
	toolBar:AddTool(GUI.ID_MOVE_BELOW, "Move Below", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DOWN, wx.wxART_MENU, toolBmpSize),   "Move task below...")
	--toolBar:AddSeparator()
	--toolBar:AddTool(GUI.ID_REPORT, "Report", wx.wxArtProvider.GetBitmap(wx.wxART_LIST_VIEW, wx.wxART_MENU, toolBmpSize),   "Generate Reports")
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

	GUI.vertSplitWin = wx.wxSplitterWindow(GUI.frame, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxSP_3D, "Main Vertical Splitter")
	GUI.vertSplitWin:SetMinimumPaneSize(10)
	
	GUI.taskTree = newGUITreeGantt(GUI.vertSplitWin)
	
	-- Panel to contain the task details and filter criteria text boxes
	local detailsPanel = wx.wxPanel(GUI.vertSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
							wx.wxDefaultSize, wx.wxTAB_TRAVERSAL, "Task Details Parent Panel")
	-- Main sizer in the detailsPanel containing everything
	local boxSizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	-- Static Box sizer to place the text boxes horizontally (Note: This sizer displays a border and some text on the top)
	local staticBoxSizer1 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Task Details")
	
	-- Task Details text box
	GUI.taskDetails = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Task Selected", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Details Box")
	staticBoxSizer1:Add(GUI.taskDetails, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer1:Add(staticBoxSizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	-- Box sizer on the right size to place the Criteria text box and above that the sizer containing the date picker control
	--   to set the dates displayed in the Gantt Grid
	local boxSizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
	-- Sizer inside box sizer2 containing the date picker controls
	local boxSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	GUI.dateStartPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
	local startDate = GUI.dateStartPick:GetValue()
	local month = wx.wxDateSpan(0,1,0,0)
	GUI.dateFinPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,startDate:Add(month), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
	boxSizer3:Add(GUI.dateStartPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer3:Add(GUI.dateFinPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer2:Add(boxSizer3,0, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	local staticBoxSizer2 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Filter Criteria")
	GUI.taskFilter = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Filter", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Filter Criteria")
	staticBoxSizer2:Add(GUI.taskFilter, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer2:Add(staticBoxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer1:Add(boxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	detailsPanel:SetSizer(boxSizer1)
	boxSizer1:Fit(detailsPanel)
	boxSizer1:SetSizeHints(detailsPanel)
	GUI.vertSplitWin:SplitHorizontally(GUI.taskTree.horSplitWin, detailsPanel)
	GUI.vertSplitWin:SetSashPosition(0.7*GUI.initFrameH)

	-- ********************EVENTS***********************************************************************
	-- Date Picker Events
	GUI.dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,GUI.dateRangeChangeEvent)
	GUI.dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,GUI.dateRangeChangeEvent)
	
	-- Frame resize event
	GUI.frame:Connect(wx.wxEVT_SIZE, GUI.frameResize)
	
	-- Task Details click event
	GUI.taskDetails:Connect(wx.wxEVT_LEFT_DOWN,function(event) print("clicked") end)
	
	-- Toolbar button events
	GUI.frame:Connect(GUI.ID_LOAD,wx.wxEVT_COMMAND_MENU_SELECTED,loadXML)
	GUI.frame:Connect(GUI.ID_SET_FILTER,wx.wxEVT_COMMAND_MENU_SELECTED,SetFilter)
	GUI.frame:Connect(GUI.ID_NEW_SUB_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,NewTask)
	GUI.frame:Connect(GUI.ID_NEW_NEXT_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,NewTask)
	GUI.frame:Connect(GUI.ID_NEW_PREV_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,NewTask)
	GUI.frame:Connect(GUI.ID_EDIT_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,EditTask)

	-- MENU COMMANDS
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
    
    -- Task selection in task tree
    GUI.taskTree:associateEventFunc({cellClickCallBack = taskInfoUpdate})
    -- *******************EVENTS FINISHED***************************************************************
    GUI.frame:Layout() -- help sizing the windows before being shown
    GUI.dateRangeChange()	-- To create the colums for the current date range in the GanttGrid

    GUI.taskTree:layout()
    
    -- Fill the task tree now
    fillTaskTree()
		
    wx.wxGetApp():SetTopWindow(GUI.frame)
    
    GUI.frame:Show(true)
end

-- Do all the initial Configuration and Initialization
Initialize()

main()



-- refreshTree()
-- fillDummyData()

-- updateTree(SporeData)


-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()