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
-- Task status colors

setfenv(1,_G)

-- Global Declarations
Globals = {
	ROOTKEY = "T0",
	PriorityList = {'1','2','3','4','5','6','7','8','9','10'},
	StatusList = {'Not Started','On Track','Behind','Done','Obsolete'}
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
require("FilterForm")		-- Containing all Filter Form GUI code

require("TestFuncs")		-- Containing all testing functions not used in final deployment

-- Main table to store the task tree that is on display
GUI.taskTreeINT = {Nodes = {}, Roots = {}, update = true, nodeCount = 0, actionQ = {},__metatable="Hidden, Do not change!"}
-- A task in Nodes or Roots will have the following attributes:
-- Expanded = if has children then true means it is expanded in the GUI
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

-- Metatable to define a node object's behaviour
GUI.nodeMeta = {__metatable = "Hidden, Do not change!"}
function GUI.nodeMeta.__index(tab,key)
	-- function to catch all accesses to a node object
	return tab._INT_TABLE[key]
end

function GUI.nodeMeta.__newindex(tab,key,val)
	-- function to catch all setting commands to taskTree nodes
	if key == "Expanded" then
		if tab._INT_TABLE.Expanded and not val then
			-- Check if updates are enabled
			if GUI.taskTreeINT.update then
				if tab._INT_TABLE.Row then
					-- Task is visible on the GUI
					-- Collapse this node in the GUI here
					-- Number of rows to collapse
					local nextNode = nil
					local rows
					local currNode
					if tab._INT_TABLE.Next then
						rows = tab._INT_TABLE.Next._INT_TABLE.Row - tab._INT_TABLE.Row - 1
						-- Decrement the rows of subsequent tasks
						nextNode = tab._INT_TABLE.Next
						while nextNode do
							nextNode._INT_TABLE.Row = nextNode._INT_TABLE.Row - rows 
							nextNode = GUI.taskTreeINT.Nodes[GUI.taskTreeINT.nextVisibleNode(nextNode,nextNode._INT_TABLE.Key)]
						end
						nextNode = tab._INT_TABLE.Next
					else
						currNode = tab._INT_TABLE.Parent
						while currNode and (not currNode._INT_TABLE.Next) do
							currNode = currNode._INT_TABLE.Parent
						end
						if currNode then
							nextNode = currNode._INT_TABLE.Next
							rows = nextNode._INT_TABLE.Row - tab._INT_TABLE.Row - 1
							-- Decrement the rows of subsequent tasks
							while nextNode do
								nextNode._INT_TABLE.Row = nextNode._INT_TABLE.Row - rows 
								nextNode = GUI.taskTreeINT.Nodes[GUI.taskTreeINT.nextVisibleNode(nextNode,nextNode._INT_TABLE.Key)]
							end
							nextNode = currNode._INT_TABLE.Next
						else
							rows = GUI.treeGrid:GetNumberRows() - tab._INT_TABLE.Row
						end
					end
					-- Make nil the Row index of all children in the hierarchy of tab
					currNode = GUI.taskTreeINT.Nodes[GUI.taskTreeINT.nextNode(tab,tab._INT_TABLE.Key)]
					while currNode ~= nextNode do
						currNode._INT_TABLE.Row = nil
						currNode = GUI.taskTreeINT.Nodes[GUI.taskTreeINT.nextNode(currNode,currNode._INT_TABLE.Key)]
					end
					-- Adjust the row labels
					if nextNode then
						for i = nextNode._INT_TABLE.Row+rows,GUI.treeGrid:GetNumberRows() do
							GUI.treeGrid:SetRowLabelValue(i-rows-1,GUI.treeGrid:GetRowLabelValue(i-1))
							GUI.ganttGrid:SetRowLabelValue(i-rows-1,GUI.ganttGrid:GetRowLabelValue(i-1))
						end		
					end			
					-- Now delete all the rows
					GUI.treeGrid:DeleteRows(tab._INT_TABLE.Row,rows)
					GUI.ganttGrid:DeleteRows(tab._INT_TABLE.Row,rows)
					GUI.treeGrid:SetRowLabelValue(tab._INT_TABLE.Row-1,"+")
				end
				-- Expanded was true and now making it false
				tab._INT_TABLE.Expanded = nil
			else
				GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ + 1] = "GUI.taskTreeINT.Nodes['"..
						tab._INT_TABLE.Key.."'].Expanded = nil"
			end		-- if GUI.taskTreeINT.update then ends
		elseif not tab._INT_TABLE.Expanded and val then
			-- Check if updates are enabled
			if GUI.taskTreeINT.update then
				if tab._INT_TABLE.Row then
					-- Task is visible on the GUI
					-- Expand the node in the GUI here
					-- Number of rows to insert
					local rows = tab._INT_TABLE.Children
					-- Increment the rows of subsequent tasks
					local nextNode = GUI.taskTreeINT.Nodes[GUI.taskTreeINT.nextVisibleNode(tab,tab._INT_TABLE.Key)]
					while nextNode do
						nextNode._INT_TABLE.Row = nextNode._INT_TABLE.Row + rows 
						nextNode = GUI.taskTreeINT.Nodes[GUI.taskTreeINT.nextVisibleNode(nextNode,nextNode._INT_TABLE.Key)]
					end
					-- Now insert the child rows here
					-- Find the hierarchy level
					local hierLevel = -1
					nextNode = tab._INT_TABLE.FirstChild
					while nextNode do
						hierLevel = hierLevel + 1
						nextNode = nextNode._INT_TABLE.Parent
					end			
					nextNode = tab._INT_TABLE.FirstChild
					local currRow = tab._INT_TABLE.Row
					while nextNode do
						currRow = currRow + 1
						nextNode._INT_TABLE.Row = currRow
						GUI.dispTask(nextNode._INT_TABLE.Row,true,nextNode,hierLevel)
						GUI.dispGantt(nextNode._INT_TABLE.Row,true,nextNode)
						nextNode = nextNode._INT_TABLE.Next
					end
					GUI.treeGrid:SetRowLabelValue(tab._INT_TABLE.Row-1,"-")
					-- Expanded was false and now making it true
					tab._INT_TABLE.Expanded = true
					-- Now check if any of the exposed children have expanded true
					nextNode = tab._INT_TABLE.FirstChild
					local toExpand = {}
					while nextNode do
						if nextNode._INT_TABLE.Expanded then
							nextNode._INT_TABLE.Expanded = nil
							toExpand[#toExpand + 1] = nextNode
						end
						nextNode = nextNode._INT_TABLE.Next
					end
					-- Perform expansion of child nodes if any
					for i = 1,#toExpand do
						toExpand[i].Expanded = true
					end
				else
					-- Expanded was false and now making it true
					tab._INT_TABLE.Expanded = true
				end
			else
				GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ + 1] = "GUI.taskTreeINT.Nodes['"..
						tab._INT_TABLE.Key.."'].Expanded = true"
			end		-- if GUI.taskTreeINT.update then ends
		end		-- if tab._INT_TABLE.Expanded and not val then ends
	elseif key == "Task" then
		-- do nothing since reserved key set automatically
	elseif key == "Children" then
		-- do nothing since reserved key set automatically
	elseif key == "FirstChild" then
		-- do nothing since reserved key set automatically
	elseif key == "LastChild" then
		-- do nothing since reserved key set automatically
	elseif key == "Selected" then
		if tab._INT_TABLE.Selected and not val then
			-- Selected was true and now making it false
			tab._INT_TABLE.Selected = nil
			-- Unselect this node in the GUI
			-- #######################################################################
		elseif not tab._INT_TABLE.Selected and val then
			-- Selected was false and now making it true
			tab._INT_TABLE.Selected = true
			-- Select the node in the GUI here
			-- #######################################################################
		end			
	elseif key == "Title" then
		-- do nothing since reserved key set automatically
	elseif key == "Key" then
		-- do nothing since reserved key set automatically
	elseif key == "Prev" then
		-- do nothing since reserved key set automatically
	elseif key == "Next" then
		-- do nothing since reserved key set automatically
	elseif key == "Parent" then
		-- do nothing since reserved key set automatically
	elseif key == "Row" then
		-- do nothing since reserved key set automatically
	else
		tab._INT_TABLE[key] = val
	end
end

GUI.taskTree = {}
function GUI.taskTreeINT.__index(tab,key)
	-- function to catch all accesses to GUI.taskTree
	return GUI.taskTreeINT[key]
end

function GUI.taskTreeINT.__newindex(tab,key,val)
	-- function to catch all setting commands to GUI.taskTree
	if key == "update" then
		if GUI.taskTreeINT.update and not val then
			-- Update was true and now making it false
			GUI.taskTreeINT.update = false
		elseif not GUI.taskTreeINT.update and val then
			GUI.taskTreeINT.update = true
			-- Now do the actionQ
			for i = 1,#GUI.taskTreeINT.actionQ do
				loadstring(GUI.taskTreeINT.actionQ[i])()
			end
			-- Clear all pending actions
			GUI.taskTreeINT.actionQ = {}
		end
	elseif key == "Nodes" then
		-- do nothing since reserved key
	elseif key == "Roots" then
		-- do nothing since reserved key
	elseif key == "nodeCount" then
		-- do nothing since reserved key
	elseif key == "actionQ" then
		-- do nothing since reserved key
	else
		GUI.taskTreeINT[key] = val
	end
end

function GUI.taskTreeINT.Clear()
	GUI.taskTreeINT.Nodes = {}
	GUI.taskTreeINT.nodeCount = 0
	GUI.taskTreeINT.Roots = {}
	GUI.treeGrid:DeleteRows(0,GUI.treeGrid:GetNumberRows())
	GUI.ganttGrid:DeleteRows(0,GUI.ganttGrid:GetNumberRows())
end

-- Function to return the iterator function to iterate over all taskTree Nodes 
-- This the function to be used in a Generic for
function GUI.taskTreeINT.tpairs(taskTree)
	-- taskTree is ignored since this is only for the GUI.taskTree table
	return GUI.taskTreeINT.nextNode, taskTree, nil
end

-- Iterator for all nodes will give the effect of iterating over all the tasks in the task tree sequentially as if the whole tree is expanded
function GUI.taskTreeINT.nextNode(node,index)
	-- node is any node of taskTreeINT it is not used by the function
	-- index is the index of the node whose next node this function returns
	local i = index
	if not i then
		return GUI.taskTreeINT.Roots[1]._INT_TABLE.Key, GUI.taskTreeINT.Roots[1]
	end
	-- Check if this node has children
	if GUI.taskTreeINT.Nodes[i]._INT_TABLE.FirstChild then
		return GUI.taskTreeINT.Nodes[i]._INT_TABLE.FirstChild._INT_TABLE.Key, GUI.taskTreeINT.Nodes[i]._INT_TABLE.FirstChild
	end
	-- No children so only way is next sibling or parents
	while GUI.taskTreeINT.Nodes[i] do
		if GUI.taskTreeINT.Nodes[i]._INT_TABLE.Next then
			return GUI.taskTreeINT.Nodes[i]._INT_TABLE.Next._INT_TABLE.Key, GUI.taskTreeINT.Nodes[i]._INT_TABLE.Next
		else
			-- No next siblings so go up a level and continue
			if GUI.taskTreeINT.Nodes[i]._INT_TABLE.Parent then
				i = GUI.taskTreeINT.Nodes[i]._INT_TABLE.Parent._INT_TABLE.Key
			else
				i = nil
			end
		end
	end		-- while GUI.taskTreeINT.Nodes[i] do ends
end

-- Function to return the iterator function to iterate over only visible taskTree Nodes
function GUI.taskTreeINT.tvpairs(taskTree)
	-- Note if GUI.taskTreeINT.update = false then the results of this iterator may not be in sync with what is seen on the GUI
	return GUI.taskTreeINT.nextVisibleNode, taskTree, nil
end

function GUI.taskTreeINT.nextVisibleNode(node, index)
	-- node is any node of the taskTreeINT, it is not used by the function
	-- index is the index of the node whose next node this function returns
	local i = index
	if not i then
		return GUI.taskTreeINT.Roots[1]._INT_TABLE.Key, GUI.taskTreeINT.Roots[1]
	end
	-- Check if this node is has children and is expanded
	if GUI.taskTreeINT.Nodes[i]._INT_TABLE.FirstChild and GUI.taskTreeINT.Nodes[i]._INT_TABLE.Expanded then
		return GUI.taskTreeINT.Nodes[i]._INT_TABLE.FirstChild._INT_TABLE.Key, GUI.taskTreeINT.Nodes[i]._INT_TABLE.FirstChild
	end
	-- No children visible so only way is next sibling or parents
	while GUI.taskTreeINT.Nodes[i] do
		if GUI.taskTreeINT.Nodes[i]._INT_TABLE.Next then
			return GUI.taskTreeINT.Nodes[i]._INT_TABLE.Next._INT_TABLE.Key, GUI.taskTreeINT.Nodes[i]._INT_TABLE.Next
		else
			-- No next siblings so go up a level and continue
			if GUI.taskTreeINT.Nodes[i]._INT_TABLE.Parent then
				i = GUI.taskTreeINT.Nodes[i]._INT_TABLE.Parent._INT_TABLE.Key
			else
				i = nil
			end
		end
	end		-- while GUI.taskTreeINT.Nodes[i] do ends					
end

function GUI.taskTreeINT.AddNode(nodeInfo)
	-- Add the node to the GUI task tree
	-- nodeInfo.Relative = relative of this new node (should be a task ID) (Can be nil - together with relation means root node)
	-- nodeInfo.Relation = relation of this new node to the Relative. This can be "Child", "Next Sibling", "Prev Sibling" (Can be nil)
	-- nodeInfo.Key = key by which this node is uniquely identified in the tree
	-- nodeInfo.Text = text to be visible to represent the node in the GUI
	-- nodeInfo.Task = Task to be associated with this node (Can be nil)
	
	-- First make sure the key is unique
	if GUI.taskTreeINT.Nodes[nodeInfo.Key] then
		-- Key already exists
		wx.wxMessageBox("Trying to add a duplicate Key ("..nodeInfo.Key..") to the task Tree.",
	                wx.wxOK + wx.wxICON_ERROR, GUI.frame)
		return nil
	end
	-- Check if Relative exist
	if nodeInfo.Relative then
		if not GUI.taskTreeINT.Nodes[nodeInfo.Relative] then
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
		GUI.taskTreeINT.Roots[#GUI.taskTreeINT.Roots + 1] = {_INT_TABLE = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children=0}}
		if GUI.taskTreeINT.Roots[#GUI.taskTreeINT.Roots - 1] then
			GUI.taskTreeINT.Roots[#GUI.taskTreeINT.Roots]._INT_TABLE.Prev = GUI.taskTreeINT.Roots[#GUI.taskTreeINT.Roots - 1]
			GUI.taskTreeINT.Roots[#GUI.taskTreeINT.Roots - 1]._INT_TABLE.Next = GUI.taskTreeINT.Roots[#GUI.taskTreeINT.Roots]
		end 
		-- Set the nodes meta table to control the node's interface
		setmetatable(GUI.taskTreeINT.Roots[#GUI.taskTreeINT.Roots],GUI.nodeMeta)
		GUI.taskTreeINT.Nodes[nodeInfo.Key] = GUI.taskTreeINT.Roots[#GUI.taskTreeINT.Roots]
		GUI.taskTreeINT.nodeCount = GUI.taskTreeINT.nodeCount + 1
		-- Add it to the GUI here
		if GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Prev then
			GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row = GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Prev._INT_TABLE.Row+1
			if GUI.taskTreeINT.update then
				GUI.dispTask(GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes[nodeInfo.Key],0)
				GUI.dispGantt(GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes[nodeInfo.Key])
			else
				-- Add to actionQ
				GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispTask(GUI.taskTreeINT.Nodes['"..
					nodeInfo.Key.."']._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes['"..nodeInfo.Key.."'],0)"
				GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispGantt(GUI.taskTreeINT.Nodes['"..
					nodeInfo.Key.."']._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes['"..nodeInfo.Key.."'])"				
			end
		else
			GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row = 1
			if GUI.taskTreeINT.update then
				GUI.dispTask(1,true,GUI.taskTreeINT.Nodes[nodeInfo.Key],0)
				GUI.dispGantt(1,true,GUI.taskTreeINT.Nodes[nodeInfo.Key])
			else
				-- Add to actionQ
				GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispTask(1,true,GUI.taskTreeINT.Nodes['"..
					nodeInfo.Key.."'],0)"
				GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispGantt(1,true,GUI.taskTreeINT.Nodes['"..
					nodeInfo.Key.."'])"
			end
		end
		-- return the node
		return GUI.taskTreeINT.Nodes[nodeInfo.Key]
	else
		-- Add it according to the relation 
		if string.upper(nodeInfo.Relation) == "CHILD" then
			-- Add child
			local parent = GUI.taskTreeINT.Nodes[nodeInfo.Relative]
			local newNode = {_INT_TABLE = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = parent}}
			parent._INT_TABLE.Children = parent._INT_TABLE.Children + 1 -- increment number of children
			if parent.FirstChild then
				-- Parent already has children
				parent._INT_TABLE.LastChild._INT_TABLE.Next = newNode
				newNode._INT_TABLE.Prev = parent._INT_TABLE.LastChild
				parent._INT_TABLE.LastChild = newNode
			else
				parent._INT_TABLE.FirstChild = newNode
				parent._INT_TABLE.LastChild = newNode
			end
			-- Set the metatable
			setmetatable(parent._INT_TABLE.LastChild,GUI.nodeMeta) 
			GUI.taskTreeINT.Nodes[nodeInfo.Key] = newNode
			GUI.taskTreeINT.nodeCount = GUI.taskTreeINT.nodeCount + 1
			-- Add it to the GUI here
			if parent._INT_TABLE.Expanded then
				-- This child needs to be displayed
				local hierLevel = 0
				local currNode = GUI.taskTreeINT.Nodes[nodeInfo.Key]
				while currNode._INT_TABLE.Parent do
					hierLevel = hierLevel + 1
					currNode = currNode._INT_TABLE.Parent
				end
				if GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Prev then
					GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row = GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Prev._INT_TABLE.Row+1
				else
					GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row = GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Parent._INT_TABLE.Row + 1
				end				
				if GUI.taskTreeINT.update then
					GUI.dispTask(GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes[nodeInfo.Key],hierLevel)
					GUI.dispGantt(GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes[nodeInfo.Key])
				else
					-- Add to actionQ
					GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispTask(GUI.taskTreeINT.Nodes['"..
						nodeInfo.Key.."']._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes['"..nodeInfo.Key.."'],"..tostring(hierLevel)..")"
					GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispTask(GUI.taskTreeINT.Nodes['"..
						nodeInfo.Key.."']._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes['"..nodeInfo.Key.."'])"
				end
			end			
			-- return the node
			return GUI.taskTreeINT.Nodes[nodeInfo.Key]
		elseif string.upper(nodeInfo.Relation) == "NEXT SIBLING" then
			-- Add next sibling
			local sib = GUI.taskTreeINT.Nodes[nodeInfo.Relative]
			local newNode = {_INT_TABLE = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = sib._INT_TABLE.Parent}}
			sib._INT_TABLE.Parent._INT_TABLE.Children = sib._INT_TABLE.Parent._INT_TABLE.Children + 1 -- increment number of children
			if sib._INT_TABLE.Next then
				-- Node needs to be inserted between these
				sib._INT_TABLE.Next._INT_TABLE.Prev = newNode
				newNode._INT_TABLE.Next = sib._INT_TABLE.Next
				sib._INT_TABLE.Next = newNode
				newNode._INT_TABLE.Prev = sib
			else
				-- Node is the last one
				sib._INT_TABLE.Next = newNode
				newNode._INT_TABLE.Prev = sib
				if sib._INT_TABLE.Parent then
					sib._INT_TABLE.Parent._INT_TABLE.LastChild = newNode
				end
			end
			-- Set the metatable
			setmetatable(parent._INT_TABLE.LastChild,GUI.nodeMeta) 
			GUI.taskTreeINT.Nodes[nodeInfo.Key] = newNode
			GUI.taskTreeINT.nodeCount = GUI.taskTreeINT.nodeCount + 1
			-- Add it to the GUI here
			if (GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Parent and 
				GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Parent._INT_TABLE.Expanded) or
				not GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Parent then
				-- This child needs to be displayed
				local hierLevel = 0
				local currNode = GUI.taskTreeINT.Nodes[nodeInfo.Key]
				while currNode._INT_TABLE.Parent do
					hierLevel = hierLevel + 1
					currNode = currNode._INT_TABLE.Parent
				end
				GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row = GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Prev._INT_TABLE.Row+1
				if GUI.taskTreeINT.update then
					GUI.dispTask(GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes[nodeInfo.Key],hierLevel)
					GUI.dispGantt(GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes[nodeInfo.Key])
				else
					-- Add to actionQ
					GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispTask(GUI.taskTreeINT.Nodes['"..
						nodeInfo.Key.."']._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes['"..nodeInfo.Key.."'],"..tostring(hierLevel)..")"
					GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispTask(GUI.taskTreeINT.Nodes['"..
						nodeInfo.Key.."']._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes['"..nodeInfo.Key.."'])"
				end
			end			
			-- return the node
			return GUI.taskTreeINT.Nodes[nodeInfo.Key]
		else 
			-- Add previous sibling
			local sib = GUI.taskTreeINT.Nodes[nodeInfo.Relative]
			local newNode = {_INT_TABLE = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = sib._INT_TABLE.Parent}}
			sib._INT_TABLE.Parent._INT_TABLE.Children = sib._INT_TABLE.Parent._INT_TABLE.Children + 1 -- increment number of children
			if sib._INT_TABLE.Prev then
				-- Node needs to be inserted between these
				sib._INT_TABLE.Prev._INT_TABLE.Next = newNode
				newNode._INT_TABLE.Prev = sib._INT_TABLE.Prev
				sib._INT_TABLE.Prev = newNode
				newNode._INT_TABLE.Next = sib
			else
				-- Node is the First one
				sib._INT_TABLE.Prev = newNode
				newNode._INT_TABLE.Next = sib
				if sib._INT_TABLE.Parent then
					sib._INT_TABLE.Parent._INT_TABLE.FirstChild = newNode
				end
			end
			-- Set the metatable
			setmetatable(parent._INT_TABLE.LastChild,GUI.nodeMeta) 
			GUI.taskTreeINT.Nodes[nodeInfo.Key] = newNode
			GUI.taskTreeINT.nodeCount = GUI.taskTreeINT.nodeCount + 1
			-- Add it to the GUI here
			if (GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Parent and 
				GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Parent._INT_TABLE.Expanded) or
				not GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Parent then
				-- This child needs to be displayed
				local hierLevel = 0
				local currNode = GUI.taskTreeINT.Nodes[nodeInfo.Key]
				while currNode._INT_TABLE.Parent do
					hierLevel = hierLevel + 1
					currNode = currNode._INT_TABLE.Parent
				end
				GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row = GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Prev._INT_TABLE.Row+1
				if GUI.taskTreeINT.update then
					GUI.dispTask(GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes[nodeInfo.Key],hierLevel)
					GUI.dispGantt(GUI.taskTreeINT.Nodes[nodeInfo.Key]._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes[nodeInfo.Key])
				else
					-- Add to actionQ
					GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispTask(GUI.taskTreeINT.Nodes['"..
						nodeInfo.Key.."']._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes['"..nodeInfo.Key.."'],"..tostring(hierLevel)..")"
					GUI.taskTreeINT.actionQ[#GUI.taskTreeINT.actionQ+1] = "GUI.dispTask(GUI.taskTreeINT.Nodes['"..
						nodeInfo.Key.."']._INT_TABLE.Row,true,GUI.taskTreeINT.Nodes['"..nodeInfo.Key.."'])"
				end
			end			
			-- return the node
			return GUI.taskTreeINT.Nodes[nodeInfo.Key]
		end
	end		-- if not nodeInfo.Relative then ends here
end
-- Set task Tree internal as the metatable for exposed task tree empty table so we can catch all accesses to the task tree table and take actions appropriately
setmetatable(GUI.taskTree, GUI.taskTreeINT)

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
			SporeData[Spores[count]] = XML2Data(xml.load(Spores[count]))
			count = count + 1
		end
	end
	SporeData[0] = count - 1
end

function GUI.dateRangeChangeEvent(event)
	GUI.dateRangeChange()
	refreshGantt()
	event:Skip()
end
function GUI.dateRangeChange()
	-- Clear the GanttGrid
	GUI.ganttGrid:DeleteRows(0,GUI.ganttGrid:GetNumberRows())
	GUI.ganttGrid:DeleteCols(0,GUI.ganttGrid:GetNumberCols())
	local startDate = GUI.dateStartPick:GetValue()
	local finDate = GUI.dateFinPick:GetValue()
	local currDate = startDate
	local count = 0
	while not currDate:IsLaterThan(finDate) do
		GUI.ganttGrid:InsertCols(count)
		-- set the column labels
		GUI.ganttGrid:SetColLabelValue(count,string.sub(toXMLDate(currDate:Format("%m/%d/%Y")),-2,-1))
		GUI.ganttGrid:AutoSizeColumn(count)
		currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
		count = count + 1
	end
end

function refreshGantt()
	-- Erase the previous data
	GUI.ganttGrid:DeleteRows(0,GUI.ganttGrid:GetNumberRows())
	local rowPtr = 0
	local hierLevel = 0
	for i,v in GUI.taskTree.tvpairs(GUI.taskTree.Nodes) do
		GUI.dispGantt(rowPtr+1,true,v)
		rowPtr = rowPtr + 1
	end		-- Looping through all the nodes ends	
end

function GUI.dispTask(row, createRow, taskNode, hierLevel)
	if (createRow and GUI.treeGrid:GetNumberRows()<row-1) then
		return nil
	end
	if not createRow and GUI.treeGrid:GetNumberRows()<row then
		return nil
	end
	if createRow then
		GUI.treeGrid:InsertRows(row-1)
		-- Now shift the row labels
		for i = GUI.treeGrid:GetNumberRows(),row,-1 do
			GUI.treeGrid:SetRowLabelValue(i,GUI.treeGrid:GetRowLabelValue(i-1))
		end
	end
	if taskNode.Children > 0 then
		if taskNode.Expanded then
			GUI.treeGrid:SetCellValue(row-1,1,string.rep(" ",hierLevel*4)..taskNode.Title)
		else
			GUI.treeGrid:SetCellValue(row-1,1,string.rep(" ",hierLevel*4)..taskNode.Title)
		end
		GUI.treeGrid:SetRowLabelValue(row-1,"+")
	else
		GUI.treeGrid:SetCellValue(row-1,1,string.rep(" ",hierLevel*4)..taskNode.Title)
		GUI.treeGrid:SetRowLabelValue(row-1," ")
	end
	if taskNode.Task and string.upper(taskNode.Task.Status) == "DONE" then
		GUI.treeGrid:SetCellValue(row-1,0,"1")
	else
		GUI.treeGrid:SetCellValue(row-1,0,"0")
	end
	GUI.treeGrid:SetReadOnly(row-1,0)
	GUI.treeGrid:SetReadOnly(row-1,1)
	-- Set the back ground color
	if taskNode.BackColor then
		GUI.treeGrid.SetCellBackgroundColour(row-1,1,wx.wxColour(taskNode.BackColor.Red,taskNode.BackColor.Green,taskNode.BackColor.Blue))
	end
	if taskNode.ForeColor then
		GUI.treeGrid:SetCellTextColour(row-1,1,wx.wxColour(taskNode.ForeColor.Red,taskNode.ForeColor.Green,taskNode.ForeColor.Blue))
	end
end

function GUI.dispGantt(row,createRow,taskNode)
	if (createRow and GUI.ganttGrid:GetNumberRows()<row-1) then
		return nil
	end
	if not createRow and GUI.ganttGrid:GetNumberRows()<row then
		return nil
	end
	if createRow then
		GUI.ganttGrid:InsertRows(row-1)
		-- Now shift the row labels
		for i = GUI.ganttGrid:GetNumberRows(),row,-1 do
			GUI.ganttGrid:SetRowLabelValue(i,GUI.ganttGrid:GetRowLabelValue(i-1))
		end
	end
	-- Now update the ganttGrid to include the schedule
	local startDay = toXMLDate(GUI.dateStartPick:GetValue():Format("%m/%d/%Y"))
	local finDay = toXMLDate(GUI.dateFinPick:GetValue():Format("%m/%d/%Y"))
	local days = GUI.ganttGrid:GetNumberCols()

--	local startDay = GUI.dateStartPick:GetValue():ToGMT()
--	local finDay = GUI.dateFinPick:GetValue():ToGMT()
--	local days = finDay:Subtract(startDay):GetDays()
	if not taskNode.Task then
		-- No task associated with the node so color the cells to show no schedule
		GUI.ganttGrid:SetRowLabelValue(row-1,"X")
		for i = 1,days do
			GUI.ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.noScheduleColor.Red,
				GUI.noScheduleColor.Green,GUI.noScheduleColor.Blue))
		end
	else
		-- Task exists so create the schedule
		--Get the datelist
		local dateList = getLatestScheduleDates(taskNode.Task)
		if not dateList then
			-- No task associated with the node so color the cells to show no schedule
			GUI.ganttGrid:SetRowLabelValue(row-1,"X")
			for i = 1,days do
				GUI.ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.noScheduleColor.Red,
					GUI.noScheduleColor.Green,GUI.noScheduleColor.Blue))
			end
		else
			local map = {Estimate="E",Commit = "C", Revs = "R", Actual = "A"}
			local map1 = {
			[1] = wx.wxDateTime.Jan,
			[2] = wx.wxDateTime.Feb,
			[3] = wx.wxDateTime.Mar,
			[4] = wx.wxDateTime.Apr,
			[5] = wx.wxDateTime.May,
			[6] = wx.wxDateTime.Jun,
			[7] = wx.wxDateTime.Jul,
			[8] = wx.wxDateTime.Aug,
			[9] = wx.wxDateTime.Sep,
			[10] = wx.wxDateTime.Oct,
			[11] = wx.wxDateTime.Nov,
			[12] = wx.wxDateTime.Dec
			}
			-- Erase the previous schedule on the row
			for i=1,days do
				GUI.ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.emptyDayColor.Red,
					GUI.emptyDayColor.Green,GUI.emptyDayColor.Blue))
			end		
			local before,after
			for i=1,#dateList do
				if dateList[i]>=startDay and dateList[i]<=finDay then
					-- This date is in range find the column which needs to be highlighted
					local currDate = wx.wxDateTimeFromDMY(tonumber(string.sub(dateList[i],-2,-1)),map1[tonumber(string.sub(dateList[i],6,7))],tonumber(string.sub(dateList[i],1,4)))
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
					local stepDate = GUI.dateStartPick:GetValue()
					while not stepDate:IsSameDate(currDate) do
						stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
						col = col + 1
					end
					GUI.ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(GUI.ScheduleColor.Red,
						GUI.ScheduleColor.Green,GUI.ScheduleColor.Blue))
					GUI.ganttGrid:SetReadOnly(row-1,col)
				else
					if dateList[i]<startDay then
						before = true
					end
					if dateList[i]>finDay then
						after = true
					end
				end
			end		-- for i=1,#dateList do ends
			local str = ""
			if before then
				str = "<"
			end
			if after then
				str = str..">"
			end
			GUI.ganttGrid:SetRowLabelValue(row-1,map[dateList.typeSchedule]..tostring(dateList.index)..str)
		end		-- if not dateList then ends
	end	
end

function GUI.labelClick(event)
	-- Find the row of the click
	local row = event:GetRow()
	if row>-1 then
		local taskNode
		-- Find the task associated with the row
		for i,v in GUI.taskTree.tvpairs(GUI.taskTree.Nodes) do
			if v.Row == row+1 then
				taskNode = v
				break
			end
		end		-- Looping through all the nodes ends
		-- Check if the taskNode has children
		if taskNode.Children > 0 then
			if taskNode.Expanded then
				taskNode.Expanded = nil
			else
				taskNode.Expanded = true
			end
		end
	end		
	--event:Skip()
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
        for i,v in GUI.taskTree.tpairs(GUI.taskTree.Nodes) do
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
    GUI.taskTree.Clear()
    GUI.taskTree.AddNode{Key=Globals.ROOTKEY, Text = "Task Spores"}
    GUI.taskTree.Nodes[Globals.ROOTKEY].ForeColor = GUI.nodeForeColor

    if SporeData[0] > 0 then
-- Populate the tree control view
		local count = 0
        for k,v in pairs(SporeData) do
        	if k~=0 then
            -- Get the tasks in the spore
-- Add the spore to the TaskTree
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
	            GUI.taskTree.AddNode{Relative=Globals.ROOTKEY, Relation="Child", Key=Globals.ROOTKEY.."_"..tostring(count), Text=strVar}
	            GUI.taskTree.Nodes[Globals.ROOTKEY.."_"..tostring(count)].ForeColor = GUI.nodeForeColor
				local taskList = applyFilterHier(Filter, v)
-- Now add the tasks under the spore in the TaskTree
            	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore
	                -- Add the 1st element under the spore
    	            local currNode = GUI.taskTree.AddNode{Relative=Globals.ROOTKEY.."_"..tostring(count), Relation="Child", Key=taskList[1].TaskID, 
    	            		Text=taskList[1].Title, Task=taskList[1]}
                	currNode.ForeColor = GUI.nodeForeColor
	                for intVar = 2,taskList.count do
	                	local cond1 = currNode.Key ~= Globals.ROOTKEY.."_"..tostring(count)
	                	local cond2 = #taskList[intVar].TaskID > #currNode.Key
	                	local cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                    	while cond1 and not (cond2 and cond3) do
                        	-- Go up the hierarchy
                        	currNode = currNode.Parent
		                	cond1 = currNode.Key ~= Globals.ROOTKEY.."_"..tostring(count)
		                	cond2 = #taskList[intVar].TaskID > #currNode.Key
		                	cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                        end
                    	-- Now currNode has the node which is the right parent
	                    currNode = GUI.taskTree.AddNode{Relative=currNode.Key, Relation="Child", Key=taskList[intVar].TaskID, 
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
        for k,currNode in GUI.taskTree.tpairs(GUI.taskTree.Nodes) do
            if expandedStatus[currNode.Key] then
                currNode.Expanded = true
			end
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

function GUI.onScrollTree(event)
	GUI.ganttGrid:Scroll(GUI.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), GUI.treeGrid:GetScrollPos(wx.wxVERTICAL))
	event:Skip()
end

function GUI.onScrollGantt(event)
	GUI.treeGrid:Scroll(GUI.treeGrid:GetScrollPos(wx.wxHORIZONTAL), GUI.ganttGrid:GetScrollPos(wx.wxVERTICAL))
	event:Skip()
end

function GUI.horSashAdjust(event)
	local info = "Sash: "..tostring(GUI.horSplitWin:GetSashPosition()).."\nCol 0: "..tostring(GUI.treeGrid:GetColSize(0)).."\nCol 1 Before: "..tostring(GUI.treeGrid:GetColSize(1))
	GUI.treeGrid:SetColMinimalWidth(1,GUI.horSplitWin:GetSashPosition()-GUI.treeGrid:GetColSize(0)-GUI.treeGrid:GetRowLabelSize(0))
	GUI.treeGrid:AutoSizeColumn(1,false)
	info = info.."\nCol 1 After: "..tostring(GUI.treeGrid:GetColSize(1))
	GUI.taskDetails:SetValue(info)	
	event:Skip()
end

function GUI.frameResize(event)
	local winSize = event:GetSize()
	local wid = 0.3*winSize:GetWidth()
	if wid > 400 then
		wid = 400
	end
	local hei = 0.6*winSize:GetHeight()
	if winSize:GetHeight() - hei > 400 then
		hei = winSize:GetHeight() - 400
	end
	-- GUI.taskDetails:SetValue("Hei="..tostring(hei).." Wid="..tostring(wid).."\n window Height="..tostring(winSize:GetHeight()).." window Width="..tostring(winSize:GetWidth()))
	GUI.horSplitWin:SetSashPosition(wid)
	GUI.treeGrid:SetColMinimalWidth(1,GUI.horSplitWin:GetSashPosition()-GUI.treeGrid:GetColSize(0)-GUI.treeGrid:GetRowLabelSize(0))
	GUI.treeGrid:AutoSizeColumn(1,false)
	
	GUI.vertSplitWin:SetSashPosition(hei)
	event:Skip()
end

function GUI.loadXML(event)
	filterFormActivate(GUI.frame)
end

function GUI.cellClick(event)
	local row = event:GetRow()
	local col = event:GetCol()
	if row>-1 then
		if col == 1 then
			local taskNode
			-- Find the task associated with the row
			for i,v in GUI.taskTree.tpairs(GUI.taskTree.Nodes) do
				v.Selected = false	-- Make everything else unselected
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			-- print("Clicked row "..tostring(row))
			taskNode.Selected = true
			GUI.taskDetails:SetValue(getTaskSummary(taskNode.Task))
		end
	end		
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
	
	local bM = wx.wxImage("LoadXML.gif",wx.wxBITMAP_TYPE_GIF)
	
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

	GUI.vertSplitWin = wx.wxSplitterWindow(GUI.frame, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxSP_3D, "Main Vertical Splitter")
	GUI.vertSplitWin:SetMinimumPaneSize(10)
	GUI.horSplitWin = wx.wxSplitterWindow(GUI.vertSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxSize(GUI.initFrameW, 0.7*GUI.initFrameH), wx.wxSP_3D, "Task Splitter")
	GUI.horSplitWin:SetMinimumPaneSize(10)
	
	GUI.treeGrid = wx.wxGrid(GUI.horSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
					wx.wxDefaultSize, 0, "Task Tree Grid")
    GUI.treeGrid:CreateGrid(1,2)
    GUI.treeGrid:SetColFormatBool(0)
    GUI.treeGrid:SetRowLabelSize(15)
    GUI.treeGrid:SetColLabelValue(0," ")
    GUI.treeGrid:SetColLabelValue(1,"Tasks")

	GUI.ganttGrid = wx.wxGrid(GUI.horSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxDefaultSize, 0, "Gantt Chart Grid")
    GUI.ganttGrid:CreateGrid(1,1)
    -- GUI.ganttGrid:SetRowLabelSize(0)

	GUI.horSplitWin:SplitVertically(GUI.treeGrid, GUI.ganttGrid)
	GUI.horSplitWin:SetSashPosition(0.3*GUI.initFrameW)
	
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
	GUI.vertSplitWin:SplitHorizontally(GUI.horSplitWin, detailsPanel)
	GUI.vertSplitWin:SetSashPosition(0.7*GUI.initFrameH)

	-- ********************EVENTS***********************************************************************
	-- SYNC THE SCROLLING OF THE TWO GRIDS	
	-- Create the scroll event to sync the 2 scroll bars in the wxScrolledWindow
	GUI.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, GUI.onScrollTree)
	GUI.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, GUI.onScrollTree)
	GUI.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, GUI.onScrollTree)
	GUI.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, GUI.onScrollTree)

	GUI.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, GUI.onScrollGantt)
	GUI.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, GUI.onScrollGantt)
	GUI.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, GUI.onScrollGantt)
	GUI.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, GUI.onScrollGantt)
	
	-- The TreeGrid label click event
	GUI.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,GUI.labelClick)
	--GUI.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,GUI.taskDblClick)
	
	-- TreeGrid left click on cell event
	GUI.treeGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,GUI.cellClick)
	
	-- Sash position changing event
	GUI.horSplitWin:Connect(wx.wxEVT_COMMAND_SPLITTER_SASH_POS_CHANGED, GUI.horSashAdjust)
	
	-- Date Picker Events
	GUI.dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,GUI.dateRangeChangeEvent)
	GUI.dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,GUI.dateRangeChangeEvent)
	
	-- Frame resize event
	GUI.frame:Connect(wx.wxEVT_SIZE, GUI.frameResize)
	
	-- Task Details click event
	GUI.taskDetails:Connect(wx.wxEVT_LEFT_DOWN,function(event) print("clicked") end)
	
	-- Toolbar button events
	GUI.frame:Connect(GUI.ID_LOAD,wx.wxEVT_COMMAND_MENU_SELECTED,GUI.loadXML)

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
    -- *******************EVENTS FINISHED***************************************************************
    GUI.frame:Layout() -- help sizing the windows before being shown
    GUI.dateRangeChange()	-- To create the colums for the current date range in the GanttGrid

	GUI.treeGrid:AutoSizeColumn(0)
    GUI.treeGrid:SetColSize(1,GUI.horSplitWin:GetSashPosition()-GUI.treeGrid:GetColSize(0)-GUI.treeGrid:GetRowLabelSize(0))
    
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
