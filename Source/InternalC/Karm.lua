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

-- Karm files
require("Filter")
require("DataHandler")

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
setfenv(1,_G)

-- Global Declarations
Globals = {
	ROOTKEY = "T0",
}

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
			-- Expanded was true and now making it false
			tab._INT_TABLE.Expanded = nil
			-- Collapse this node in the GUI here
			-- #######################################################################
		elseif not tab._INT_TABLE.Expanded and val then
			-- Expanded was false and now making it true
			tab._INT_TABLE.Expanded = true
			-- Expand the node in the GUI here
			-- #######################################################################
		end
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

function GUI.taskTreeINT.Nodes.Clear()
	if GUI.taskTree.update then
		GUI.taskTreeINT.Nodes = {}
		GUI.taskTreeINT.nodeCount = 0
		GUI.taskTreeINT.Roots = {}
		GUI.treeGrid:DeleteRows(0,GUI.treeGrid:GetNumberRows())
		GUI.ganttGrid:DeleteRows(0,GUI.ganttGrid:GetNumberRows())
	else
		GUI.taskTree.actionQ[#GUI.taskTree.actionQ + 1]="GUI.taskTreeINT.Nodes.Clear()"
	end
end

-- Function to return the iterator function to iterate over all taskTree Nodes 
-- This the function to be used in a Generic for
function GUI.taskTreeINT.Nodes.tpairs(taskTree)
	-- taskTree is ignored since this is only for the GUI.taskTree table
	return (
		-- Iterator for all nodes will give the effect of iterating over all the tasks in the task tree sequentially as if the whole tree is expanded
		function (node,index)
			-- node is any node of taskTreeINT it is not used by the function
			-- index is the index of the node whose next node this function returns
			local i = index
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
	), taskTree, GUI.taskTreeINT.Roots[1]._INT_TABLE.Key
end

-- Function to return the iterator function to iterate over only visible taskTree Nodes
function GUI.taskTreeINT.Nodes.tvpairs(taskTree)
	-- Note if GUI.taskTreeINT.update = false then the results of this iterator may not be in sync with what is seen on the GUI
	return (
		-- Iterator for all visible nodes, will give the effect of iterating over all the visible tasks in the taskGrid
		function(node, index)
			-- node is any node of the taskTreeINT, it is not used by the function
			-- index is the index of the node whose next node this function returns
			local i = index
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
	), taskTree, GUI.taskTreeINT.Roots[1]._INT_TABLE.Key
end

function GUI.taskTreeINT.Nodes.Add(nodeInfo)
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
		--#################################################################
		
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
			--#################################################################
			
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
				-- Add it to the GUI here
				--#################################################################
			else
				-- Node is the last one
				sib._INT_TABLE.Next = newNode
				newNode._INT_TABLE.Prev = sib
				if sib._INT_TABLE.Parent then
					sib._INT_TABLE.Parent._INT_TABLE.LastChild = newNode
				end
				-- Add it to the GUI here
				--#################################################################
			end
			-- Set the metatable
			setmetatable(parent._INT_TABLE.LastChild,GUI.nodeMeta) 
			GUI.taskTreeINT.Nodes[nodeInfo.Key] = newNode
			GUI.taskTreeINT.nodeCount = GUI.taskTreeINT.nodeCount + 1
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
				-- Add it to the GUI here
				--#################################################################
			else
				-- Node is the First one
				sib._INT_TABLE.Prev = newNode
				newNode._INT_TABLE.Next = sib
				if sib._INT_TABLE.Parent then
					sib._INT_TABLE.Parent._INT_TABLE.FirstChild = newNode
				end
				-- Add it to the GUI here
				--#################################################################
			end
			-- Set the metatable
			setmetatable(parent._INT_TABLE.LastChild,GUI.nodeMeta) 
			GUI.taskTreeINT.Nodes[nodeInfo.Key] = newNode
			GUI.taskTreeINT.nodeCount = GUI.taskTreeINT.nodeCount + 1
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

function updateTree(treeData)
	-- treeData should be the array of spore dataStruct returned by XML2DATA
	GUI.treeGrid:DeleteRows(0,GUI.treeGrid:GetNumberRows())
	GUI.ganttGrid:DeleteRows(0,GUI.ganttGrid:GetNumberRows())
	local taskTree = {}	-- Table to store the GUI state which will replace the GUI.taskTree table
	local rowPtr = 0
	local hierLevel = 0
	for i,spore in pairs(treeData) do
		if i ~=0 then
			local counts = {[spore] = 1} -- to count the children in the spore/task
			while(spore[counts[spore]] or spore.parent) do
				if not spore[counts[spore]] then
					-- go up a level
					spore = spore.parent
					hierLevel = hierLevel - 1
				else
					if spore[counts[spore]].Title then
						GUI.treeGrid:InsertRows(rowPtr)
						GUI.treeGrid:SetCellValue(rowPtr,0,string.rep(" ",hierLevel*4)..spore[counts[spore]].Title)
						rowPtr = rowPtr + 1
					end
					if spore[counts[spore]].SubTasks then
						spore = spore[counts[spore]].SubTasks
						hierLevel = hierLevel + 1
						counts[spore] = 0
					end
				end
				counts[spore] = counts[spore] + 1
			end		-- while(treeData[i]) ends
		end		-- if i ~=0 then ends
	end		-- Looping through all the spores	
	GUI.treeGrid:SetColMinimalWidth(0,GUI.horSplitWin:GetSashPosition())
	GUI.treeGrid:AutoSizeColumn(0,false)
end		-- function updateTree(treeData) ends

function GUI.dispTask(row, createRow, taskNode, hierLevel)
	if createRow and GUI.treeGrid:GetNumberRows()<row-1 or GUI.treeGrid:GetNumberRows()<row then
		return nil
	end
	if createRow then
		GUI.treeGrid:InsertRows(row)
	end
	GUI.treeGrid:SetCellValue(rowPtr,0,string.rep(" ",hierLevel*4)..taskNode.Text)
	-- Now update the ganttGrid to include the schedule
	local startDay = GUI.dateStartPick:Getvalue():ToGMT()
	local finDay = GUI.dateFinPick:GetValue():ToGMT()
	local days = startDay:Subtract(finDay):GetDays()
	if not taskNode.Task then
		-- No task associated with the node so color the cells to show no schedule
		GUI.ganttGrid:SetRowLabelValue(row-1,"X")
		for i = 1,days do
			GUI.ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(GUI.noScheduleColor.Red,
			,GUI.noScheduleColor.Green,GUI.noScheduleColor.Blue))
		end
	else
		-- Task exists so create the schedule
		--Get the datelist
		local dateList = getLatestScheduleDates(taskNode.Task)
		for i=1,#dateList do
			local start = toXMLDate(startDay.Format("%D"))
			local fin = toXMLDate(finDay.Format("%D"))
			if dateList[i]>=start and dateList[i]<=fin then
				-- This date is in range
				
			end
		end
	end	
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
        for i,v in GUI.taskTree.Nodes.tpairs(GUI.taskTree.Nodes) do
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
    GUI.taskTree.Nodes.Clear()
    GUI.taskTree.Nodes.Add{Key=Globals.ROOTKEY, Text = "Task Spores"}
    GUI.taskTree.Nodes(Globals.ROOTKEY).ForeColor = GUI.nodeForeColor

    if SporeData[0] > 0 then
-- Populate the tree control view
		local count = 0
        for k,v in pairs(SporeData) do
        	if k~=0 then
            -- Get the tasks in the spore
-- Add the spore to the TaskTree
				local strVar
				count = count + 1
            	for intVar = #k,1,-1 do
            		local intVar1 = -1
                	if string.sub(k, intVar, intVar) == "." then
                    	intVar1 = intVar
                	end
                	if string.sub(k, intVar, intVar) == "\\" or string.sub(k, intVar, intVar) == "/" then
                    	strVar = string.sub(k, intVar + 1, intVar1)
                    	break
                	end
            	end
	            GUI.taskTree.Nodes.Add{Relative=Globals.ROOTKEY, Relation="Child", Key=Globals.ROOTKEY.."_"..tostring(count), Text=strVar}
	            GUI.taskTree.Nodes[Globals.ROOTKEY.."_"..tostring(count)].ForeColor = GUI.nodeForeColor
				local taskList = applyFilterHier(Filter, v)
-- Now add the tasks under the spore in the TaskTree
            	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore
	                -- Add the 1st element under the spore
    	            local currNode = GUI.taskTree.Nodes.Add{Relative=Globals.ROOTKEY.."_"..tostring(count), Relation="Child", Key=taskList[1].TaskID, Text=taskList[1].Title}
                	currNode.ForeColor = GUI.nodeForeColor
	                for intVar = 2,taskList.count do
                    	while currNode.Key ~= Globals.ROOTKEY.."_"..tostring(count) and not #taskList[intVar].TaskID > #currNode.Key and 
                      			string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_" do
                        	-- Go up the hierarchy
                        	currNode = currNode.Parent
                        end
                    	-- Now currNode has the node which is the right parent
	                    currNode = GUI.taskTree.Nodes.Add{Relative=currNode.Key, Relation="Child", Key=taskList[intVar].TaskID, Text=taskList[intVar].Title}
                    	currNode.ForeColor = nodeColor
                    end
	            end  -- if taskList.count > 0 then ends
			end		-- if k~=0 then ends
-- Repeat for all spores
        end		-- for k,v in pairs(SporeData) do ends
    end  -- if SporeData[0] > 0 then ends
    
    if restorePrev then
-- Update the tree status to before the refresh
        for k,currNode in GUI.taskTree.Nodes.tpairs(GUI.taskTree.Nodes) do
            if expandedStatus[currNode.Key] then
                currNode.Expanded = true
			end
            if currNode.Key == prevSelect then
                currNode.Selected = true
            end
        end
    else
        GUI.taskTree.Nodes[Globals.ROOTKEY].Expanded = true
    end
    --Call TaskTree_Click
end
--@@END@@

--'****f* Karm/Control_Panel/TaskTree_Click
--' FUNCTION
--' Function to handle the click ever on the task tree
--' The function checks which task is selected and updates the task information in the task details panel
--'
--' SOURCE
--Private Sub TaskTree_Click()
--'@@END@@
--    Dim currNode As Node
--    Dim taskElem As IXMLDOMElement
--    Dim strVar As String
--    Dim intVar As Integer
--    Dim intVar1 As Integer
--    Dim intVar2 As Integer
--    Dim comment As String
--    
--    'Get the selected node
--    For Each currNode In TaskTree.Nodes
--        If currNode.selected Then
--            Exit For
--        End If
--    Next
--    If Not (currNode Is Nothing) Then
--        'Check here if the currNode is the root node or a spore node
--        If Left(currNode.Key, Len(Globals.ROOTKEY)) = Globals.ROOTKEY Then
--            If currNode.Key = Globals.ROOTKEY Then
--                strVar = "The Tree Root Node. All the Task Spore files are listed under this node."
--            Else
--                strVar = "Task Spore node with name corresponding to the spore file it represents."
--            End If  'If currNode.Key = Globals.ROOTKEY
--        Else
--            Set taskElem = XML.GetElemFromKey(currNode.Key)
--            'Parse the task Element to get the task Information
--            For intVar = 0 To taskElem.ChildNodes.Length - 1
--                If taskElem.ChildNodes(intVar).NodeType = NODE_ELEMENT Then
--                    If UCase(taskElem.ChildNodes(intVar).nodeName) = "TASKID" Then
--                        strVar = strVar & vbCrLf & "Task ID: " & taskElem.ChildNodes(intVar).Text
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "DATE_DUE" Then
--                        strVar = strVar & vbCrLf & "Due Date: " & taskElem.ChildNodes(intVar).Text
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "COMMENTS" Then
--                        comment = "Comments: " & taskElem.ChildNodes(intVar).Text
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "STATUS" Then
--                        For intVar1 = 0 To taskElem.ChildNodes(intVar).ChildNodes.Length - 1
--                            If taskElem.ChildNodes(intVar).ChildNodes(intVar1).NodeType = NODE_ELEMENT Then
--                                If UCase(taskElem.ChildNodes(intVar).ChildNodes(intVar1).nodeName) = "STATUS" Then
--                                    strVar = strVar & vbCrLf & "Status: " & taskElem.ChildNodes(intVar).ChildNodes(intVar1).Text
--                                    Exit For
--                                End If
--                            End If
--                        Next intVar1
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "WHO" Then
--                        strVar = strVar & vbCrLf & "People: "
--                        For intVar1 = 0 To taskElem.ChildNodes(intVar).ChildNodes.Length - 1
--                            If taskElem.ChildNodes(intVar).ChildNodes(intVar1).NodeType = NODE_ELEMENT Then
--                                For intVar2 = 0 To taskElem.ChildNodes(intVar).ChildNodes(intVar1).ChildNodes.Length - 1
--                                    If taskElem.ChildNodes(intVar).ChildNodes(intVar1).ChildNodes(intVar2).NodeType = NODE_ELEMENT Then
--                                        If UCase(taskElem.ChildNodes(intVar).ChildNodes(intVar1).ChildNodes(intVar2).nodeName) = "ID" Then
--                                            strVar = strVar & taskElem.ChildNodes(intVar).ChildNodes(intVar1).ChildNodes(intVar2).Text & ", "
--                                        End If
--                                    End If
--                                Next intVar2
--                            End If  'If whoElem.ChildNodes(intVar).NodeType = NODE_ELEMENT ends here
--                        Next intVar1
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "PRIORITY" Then
--                        strVar = strVar & vbCrLf & "Priority: " & taskElem.ChildNodes(intVar).Text
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "SCHEDULE" Then
--                        strVar = strVar & vbCrLf & "Schedule: Planned"
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "CATEGORY" Then
--                        strVar = strVar & vbCrLf & "Category: " & taskElem.ChildNodes(intVar).Text
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "SUB-CATEGORY" Then
--                        strVar = strVar & vbCrLf & "Sub-Category: " & taskElem.ChildNodes(intVar).Text
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "TAGS" Then
--                        strVar = strVar & vbCrLf & "Tags: "
--                        For intVar1 = 0 To taskElem.ChildNodes(intVar).ChildNodes.Length - 1
--                            If taskElem.ChildNodes(intVar).ChildNodes(intVar1).NodeType = NODE_ELEMENT Then
--                                If UCase(taskElem.ChildNodes(intVar).ChildNodes(intVar1).nodeName) = "TAG" Then
--                                    strVar = strVar & taskElem.ChildNodes(intVar).ChildNodes(intVar1).Text & ","
--                                End If
--                            End If
--                        Next intVar1
--                    ElseIf UCase(taskElem.ChildNodes(intVar).nodeName) = "SUBTASKS" Then
--                    End If
--                End If  'If taskElem.ChildNodes(intVar).NodeType = NODE_ELEMENT
--            Next intVar
--        End If  'If Left(currNode.Key, Len(Globals.ROOTKEY)) = Globals.ROOTKEY
--        strVar = strVar & vbCrLf & comment
--    Else
--        strVar = "Nothing selected in the tree."
--    End If  'If Not (currNode Is Nothing)
--    TaskInfoLabel.Text = strVar
--End Sub



function onScrollTree(event)
	GUI.ganttGrid:Scroll(GUI.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), GUI.treeGrid:GetScrollPos(wx.wxVERTICAL))
	event:Skip()
end

function onScrollGantt(event)
	GUI.treeGrid:Scroll(GUI.treeGrid:GetScrollPos(wx.wxHORIZONTAL), GUI.ganttGrid:GetScrollPos(wx.wxVERTICAL))
	event:Skip()
end

function horSashAdjust(event)
	GUI.treeGrid:SetColMinimalWidth(0,GUI.horSplitWin:GetSashPosition())
	GUI.treeGrid:AutoSizeColumn(0,false)
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
	GUI.dateFinPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
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
		
    wx.wxGetApp():SetTopWindow(GUI.frame)
    
    GUI.frame:Show(true)
end

-- Do all the initial Configuration and Initialization
Initialize()

main()

fillDummyData()

updateTree(SporeData)


-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
