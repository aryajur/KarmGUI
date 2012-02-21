-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application Criteria Entry form UI creation and handling file
-- Author:      Milind Gupta
-- Created:     2/09/2012
-----------------------------------------------------------------------------

--local print = print
--local wx = wx
--local bit = bit
--local GUI = GUI
--local tostring = tostring
--local Globals = Globals
--local setmetatable = setmetatable
--local NewID = NewID
--local type = type
--local math = math
--local error = error
--module(...)

local modname = ...

M = {}
package.loaded[modname] = M
setmetatable(M,{["__index"]=_G})
setfenv(1,M)

-- Local filter table to store the filter criteria
filter = {}

noStr = {
	Cat = Globals.NoCatStr,
	SubCat = Globals.NoSubCatStr,
	Priority = Globals.NoPriStr
}

local function SelTaskPress(event)
	setfenv(1,package.loaded[modname])
	local frame = wx.wxFrame(frame, wx.wxID_ANY, "Select Task", wx.wxDefaultPosition,
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
	local taskTree = wx.wxTreeCtrl(frame, wx.wxID_ANY, wx.wxDefaultPosition,wx.wxSize(0.9*GUI.initFrameW, 0.9*GUI.initFrameH),bit.bor(wx.wxTR_SINGLE,wx.wxTR_HAS_BUTTONS))
	MainSizer:Add(taskTree, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
	local OKButton = wx.wxButton(frame, wx.wxID_ANY, "OK", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	local CancelButton = wx.wxButton(frame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	local CheckBox = wx.wxCheckBox(frame, wx.wxID_ANY, "Subtasks", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	
	if filter.Tasks and filter.Tasks.Children then
		CheckBox:SetValue(true)
	end
	buttonSizer:Add(OKButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	buttonSizer:Add(CancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	buttonSizer:Add(CheckBox,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	
	-- Now populate the tree with all the tasks
	
	-- Add the root
	local root = taskTree:AddRoot("Task Spores")
	local treeData = {}
	treeData[root:GetValue()] = Globals.ROOTKEY
	-- Loop through all the spores
	for k,v in pairs(SporeData) do
       	if k~=0 then
       		-- Add the spore here
			-- Find the name of the file
			local strVar
    		local intVar1 = -1
        	for intVar = #k,1,-1 do
            	if string.sub(k, intVar, intVar) == "." then
                	intVar1 = intVar
            	end
            	if string.sub(k, intVar, intVar) == "\\" or string.sub(k, intVar, intVar) == "/" then
                	strVar = string.sub(k, intVar + 1, intVar1-1)
                	break
            	end
        	end
        	-- Add the spore node
            local currNode = taskTree:AppendItem(root,strVar)
			treeData[currNode:GetValue()] = Globals.ROOTKEY..k
			if filter.Tasks and #filter.Tasks.TaskID > #Globals.ROOTKEY and 
			  string.sub(filter.Tasks.TaskID,#Globals.ROOTKEY + 1, -1) == k then
				taskTree:EnsureVisible(currNode)
				taskTree:SelectItem(currNode)
			end
			local hier = v
			local hierCount = {}
			-- Traverse the task hierarchy here
			hierCount[hier] = {}
			hierCount[hier].count = 0
			hierCount[hier].parent = currNode
			while hierCount[hier].count < #hier or hier.parent do
				if not(hierCount[hier].count < #hier) then
					hier = hier.parent
				else
					-- Increment the counter
					hierCount[hier].count = hierCount[hier].count + 1
					currNode = taskTree:AppendItem(hierCount[hier].parent,hier[hierCount[hier].count].Title)
					treeData[currNode:GetValue()] = hier[hierCount[hier].count].TaskID
					if filter.Tasks and filter.Tasks.TaskID == hier[hierCount[hier].count].TaskID then
						taskTree:EnsureVisible(currNode)
						taskTree:SelectItem(currNode)
					end
					if hier[hierCount[hier].count].SubTasks then
						-- This task has children so go deeper in the hierarchy
						hier = hier[hierCount[hier].count].SubTasks
						hierCount[hier] = {}
						hierCount[hier].parent = currNode 
						hierCount[hier].count = 0
					end
				end
			end		-- while hierCount[hier] < #hier or hier.parent do ends here
		end		-- if k~=0 then ends
	end
	-- Expand the root element
	taskTree:Expand(root)
	
	-- Connect the button events
	OKButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
	function (event)
		setfenv(1,package.loaded[modname])
		local sel = taskTree:GetSelection()
		-- Setup the filter
		filter.Tasks = {}
		if treeData[sel:GetValue()] == Globals.ROOTKEY then
			filter.Tasks = nil
		else
			-- This is a spore node
			if CheckBox:GetValue() then
				filter.Tasks.Children = true
			end
			filter.Tasks.TaskID = treeData[sel:GetValue()] 
		end
		-- Setup the label properly
		if filter.Tasks then
			if filter.Tasks.Children then
				FilterTask:SetLabel(taskTree:GetItemText(sel).." and Children")
			else
				FilterTask:SetLabel(taskTree:GetItemText(sel))
			end
		else
			FilterTask:SetLabel("No Task Selected")
		end	
		frame:Close()
	end
	)
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
	function (event)
		setfenv(1,package.loaded[modname])		
		frame:Close()
	end
	)
	
	
	frame:SetSizer(MainSizer)
	MainSizer:SetSizeHints(frame)
	frame:Layout()
	frame:Show(true)
end

function getTagUnit()
	-- Return the selected item in Tag List
	local item = TagList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
	if item == -1 then
		return nil
	else 
		return TagList:GetItemText(item)		
	end
end

function UpdateLists()

end

function filterFormActivate(parent)
	frame = wx.wxFrame(parent, wx.wxID_ANY, "Filter Form", wx.wxDefaultPosition,
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		MainBook = wx.wxNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP)
			-- Task, Categories and Sub-Categories Page
			TandC = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
				local TandCSizer = wx.wxBoxSizer(wx.wxVERTICAL)
					local TaskSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
					SelTaskButton = wx.wxButton(TandC, wx.wxID_ANY, "Select Task", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					TaskSizer:Add(SelTaskButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					FilterTask = wx.wxStaticText(TandC, wx.wxID_ANY, "No Task Selected", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					TaskSizer:Add(FilterTask, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					ClearTaskButton = wx.wxButton(TandC, wx.wxID_ANY, "Clear Task", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					TaskSizer:Add(ClearTaskButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					TandCSizer:Add(TaskSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

					CategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, "Select Categories", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					TandCSizer:Add(CategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					
					-- Category List boxes and buttons
					CatCtrl = MultiSelectCtrl.new(TandC,"Cat",true,{"item 1","item 3","item 2", "item 1"})
					--CatCtrl.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,MultiSelectCtrl.AddPress)
					TandCSizer:Add(CatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					
					SubCategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, "Select Sub-Categories", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					TandCSizer:Add(SubCategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					-- Sub Category Listboxes and Buttons
					SubCatCtrl = MultiSelectCtrl.new(TandC,"SubCat",true,{"item 1","item 2","item 3"},{"item 1","item 2","item 3"})
					TandCSizer:Add(SubCatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				TandC:SetSizer(TandCSizer)
			TandCSizer:SetSizeHints(TandC)
		MainBook:AddPage(TandC, "Task and Category")
		
		-- Priorities Status and Tags page
		PSandTag = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local PSandTagSizer = wx.wxBoxSizer(wx.wxVERTICAL) 
				PriorityLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, "Select Priorities", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				PSandTagSizer:Add(PriorityLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Priority List boxes and buttons
				PriCtrl = MultiSelectCtrl.new(PSandTag,"Priority",true,Globals.PriorityList)
				PSandTagSizer:Add(PriCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				StatusLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, "Select Status", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				PSandTagSizer:Add(StatusLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Status List boxes and buttons
				StatCtrl = MultiSelectCtrl.new(PSandTag,"Status",false,Globals.StatusList)
				PSandTagSizer:Add(StatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				TagsLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, "Select Tags", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				PSandTagSizer:Add(TagsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Tag List box, buttons and tree
				local TagSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
					TagList = wx.wxListCtrl(PSandTag, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(0.1*GUI.initFrameW, 0.1*GUI.initFrameH),
						bit.bor(wx.wxLC_REPORT,wx.wxLC_NO_HEADER,wx.wxLC_SINGLE_SEL))
					-- Populate the tag list here
					local tagList = {'tag 1','tag 2','tag 3','tag 9','tag 8','tag 7','tag 6','tag 5','tag 4'}
					local col = wx.wxListItem()
					col:SetId(0)
					TagList:InsertColumn(0,col)
					for i=1,#tagList do
						MultiSelectCtrl.InsertItem(TagList,tagList[i])
					end
					
					TagSizer:Add(TagList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					TagBoolCtrl = BooleanTreeCtrl.new(PSandTag,TagSizer,getTagUnit, "Tags")
				PSandTagSizer:Add(TagSizer, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			PSandTag:SetSizer(PSandTagSizer)
			PSandTagSizer:SetSizeHints(PSandTag)
		MainBook:AddPage(PSandTag, "Priorities,Status and Tags")
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	local ButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
	ToBaseButton = wx.wxButton(frame, wx.wxID_ANY, "Current to Base", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	ButtonSizer:Add(ToBaseButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	CancelButton = wx.wxButton(frame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	ButtonSizer:Add(CancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	ApplyButton = wx.wxButton(frame, wx.wxID_ANY, "Apply", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	ButtonSizer:Add(ApplyButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	MainSizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	frame:SetSizer(MainSizer)
	MainSizer:SetSizeHints(frame)
	
	-- Connect event handlers to the buttons
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function (event)
			setfenv(1,package.loaded[modname])		
			frame:Close()
		end
	)
	

--	Connect(wxID_ANY,wxEVT_CLOSE_WINDOW,(wxObjectEventFunction)&CriteriaFrame::OnClose);

	-- Task Selection/Clear button press event
	SelTaskButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, SelTaskPress)
	ClearTaskButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function (event)
			setfenv(1,package.loaded[modname])
			filter.Tasks = nil
			FilterTask:SetLabel("No Task Selected")
		end
	)
	

    frame:Layout() -- help sizing the windows before being shown

    frame:Show(true)
end

-- Boolean Tree and Boolean button
BooleanTreeCtrl = {
	
	BooleanExpression = function(tree)
		local currNode = tree:GetFirstChild(tree:GetRootItem())
		local expr = BooleanTreeCtrl.treeRecurse(tree,currNode)
		return expr		
	end,
	
	treeRecurse = function(tree,node)
		local itemText = tree:GetItemText(node) 
		if itemText == "(AND)" or itemText == "(OR)" or itemText == "NOT(OR)" or itemText == "NOT(AND)" then
			local retText = "(" 
			local logic = " "..string.match(itemText,"%((.-)%)").." "
			if string.sub(itemText,1,3) == "NOT" then
				retText = "NOT("
			end
			local currNode = tree:GetFirstChild(node)
			retText = retText..BooleanTreeCtrl.treeRecurse(tree,currNode)
			currNode = tree:GetNextSibling(currNode)
			while currNode:IsOk() do
				retText = retText..logic..BooleanTreeCtrl.treeRecurse(tree,currNode)
				currNode = tree:GetNextSibling(currNode)
			end
			return retText..")"
		elseif itemText == "NOT()" then
			return "NOT("..BooleanTreeCtrl.treeRecurse(tree,tree:GetFirstChild(node))..")"
		else
			return itemText
		end
	end,
	
	CopyTree = function(treeObj,srcItem,destItem)
		-- This will copy the srcItem and its child tree to as a child of destItem
		if not srcItem:IsOk() or not destItem:IsOk() then
			error("Expected wxTreeItemIds",2)
		end
		local tree = treeObj.SelTree
		local currSrcNode = srcItem
		local currDestNode = destItem
		-- Copy the currSrcNode under the currDestNode
		currDestNode = tree:AppendItem(currDestNode,tree:GetItemText(currSrcNode))
		-- Check if any children
		if tree:ItemHasChildren(currSrcNode) then
			currSrcNode = tree:GetFirstChild(currSrcNode)
			while true do
				-- Copy the currSrcNode under the currDestNode
				local currNode = tree:AppendItem(currDestNode,tree:GetItemText(currSrcNode))
				-- Check if any children
				if tree:ItemHasChildren(currSrcNode) then
					currDestNode = currNode
					currSrcNode = tree:GetFirstChild(currSrcNode)
				elseif tree:GetNextSibling(currSrcNode):IsOk() then
					-- There are more items in the same level
					currSrcNode = tree:GetNextSibling(currSrcNode)
				else
					-- No children and no further siblings so go up
					currSrcNode = tree:GetItemParent(currSrcNode)
					currDestNode = tree:GetItemParent(currDestNode)
					while not tree:GetNextSibling(currSrcNode):IsOk() and not(currSrcNode:GetValue() == srcItem:GetValue()) do
						currSrcNode = tree:GetItemParent(currSrcNode)
						currDestNode = tree:GetItemParent(currDestNode)
					end
					if currSrcNode:GetValue() == srcItem:GetValue() then
						break
					end
					currSrcNode = tree:GetNextSibling(currSrcNode)
				end		-- if tree:ItemHasChildren(currSrcNode) then ends
			end		-- while true do ends
		end		-- if tree:ItemHasChildren(currSrcNode) then ends
	end,
	
	DelTree = function(treeObj,item)
		if not item:IsOk() then
			error("Expected proper wxTreeItemId",2)
		end
		local tree = treeObj.SelTree
		local currNode = item
		if tree:ItemHasChildren(currNode) then
			currNode = tree:GetFirstChild(currNode)
			while true do
				-- Check if any children
				if tree:ItemHasChildren(currNode) then
					currNode = tree:GetFirstChild(currNode)
				elseif tree:GetNextSibling(currNode):IsOk() then
					-- delete this node
					-- There are more items in the same level
					local next = tree:GetNextSibling(currNode)
					tree:Delete(currNode)
					currNode = next 
				else
					-- No children and no further siblings so delete and go up
					local parent = tree:GetItemParent(currNode)
					tree:Delete(currNode)
					currNode = parent
					while not tree:GetNextSibling(currNode):IsOk() and not(currNode:GetValue() == item:GetValue()) do
						parent = tree:GetItemParent(currNode)
						tree:Delete(currNode)
						currNode = parent
					end
					if currNode:GetValue() == item:GetValue() then
						break
					end
					currNode = tree:GetNextSibling(currNode)
				end		-- if tree:ItemHasChildren(currSrcNode) then ends
			end		-- while true do ends
		end		-- if tree:ItemHasChildren(currNode) then ends
		tree:Delete(currNode)		
	end,
	
	DeletePress = function(event)
		setfenv(1,package.loaded[modname])
		local ob = BooleanTreeCtrl[event:GetId()]
		local Sel = ob.object.SelTree:GetSelections(Sel)	
		-- Check if anything selected
		if #Sel == 0 then
			return nil
		end
		-- Delete all selected
		for i=1,#Sel do
			ob.object:DelTree(Sel[i])
		end
	end,
	
	NegatePress = function(event)
		setfenv(1,package.loaded[modname])
		local ob = BooleanTreeCtrl[event:GetId()]
		local Sel = ob.object.SelTree:GetSelections(Sel)	
		-- Check if anything selected
		if #Sel == 0 then
			return nil
		end
		local parent = ob.object.SelTree:GetItemParent(Sel[1])
		if #Sel == 1 then
			-- Single Selection
			local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
			ob.object:CopyTree(Sel[1],currNode)
			ob.object:DelTree(Sel[1])
		else
			-- Multiple Selection
			-- First move the selections to a correct new node
			local parentText = ob.object.SelTree:GetItemText(parent)
			if parentText == "(OR)" or parentText == "NOT(OR)" then
				parentText = "NOT(OR)"
			elseif parentText == "(AND)" or parentText == "NOT(AND)" then
				parentText = "NOT(AND)" 
			end
			parent = ob.object.SelTree:AppendItem(ob.object.SelTree:GetItemParent(Sel[1]),parentText)
			for i = 1,#Sel do
				ob.object:CopyTree(Sel[i],parent)
				ob.object:DelTree(Sel[i])
			end
		end
	end,
	
	LogicPress = function(event)
		setfenv(1,package.loaded[modname])
		local ob = BooleanTreeCtrl[event:GetId()]
		-- Get the Logic Unit
		local unit = ob.object.getInfo()
		if not unit then
			return nil
		end
		
		local root = ob.object.SelTree:GetRootItem()
		if ob.object.SelTree:GetCount() == 1 then
			-- Just add this first object
			local currNode = ob.object.SelTree:AppendItem(root,unit)
			ob.object.SelTree:Expand(root)
			return nil
		end
		-- More than 1 item in the tree so now find the selections and  modify the tree
		local Sel = ob.object.SelTree:GetSelections(Sel)
		-- Check if anything selected
		if #Sel == 0 then
			return nil
		end
		-- Check if root node selected
		if #Sel == 1 and ob.object.SelTree:GetRootItem():GetValue() == Sel[1]:GetValue() then
			-- Root item selected clear Sel and fill up with all children of root
			Sel = {}
			local node = ob.object.SelTree:GetFirstChild(ob.object.SelTree:GetRootItem())
			Sel[#Sel + 1] = node
			node = ob.object.SelTree:GetNextSibling(node)
			while node:IsOk() do
				Sel[#Sel + 1] = node
				node = ob.object.SelTree:GetNextSibling(node)
			end
		end
		local added = nil
		if #Sel > 1 then
			-- Check if all children selected
			local parent = ob.object.SelTree:GetItemParent(Sel[1])
			if #Sel == ob.object.SelTree:GetChildrenCount(parent,false) then
				-- All children of parent are selected
				-- Check if the unit can be added under the parent itself
				local parentText = ob.object.SelTree:GetItemText(parent)
				if ((ob.button == "AND" or ob.button == "NAND" or ob.button == "ANDN" or ob.button == "NANDN") and 
						(parentText == "(AND)" or parentText == "NOT(AND)")) or
				   ((ob.button == "OR" or ob.button == "NOR" or ob.button == "ORN" or ob.button == "NORN") and 
				   		(parentText == "(OR)" or parentText == "NOT(OR)")) then
					-- Add the unit under parent
					if ob.button == "AND" or ob.button == "OR" then
						-- Add to parent directly
						ob.object.SelTree:AppendItem(parent,unit)
					elseif ob.button == "NAND" or ob.button == "NOR" then
						-- Add to parent by negating first
						local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
						ob.object.SelTree:AppendItem(currNode,unit)
					elseif ob.button == "ANDN" or ob.button == "ORN" or ob.button == "NANDN" or ob.button == "NORN" then
						if parentText == "(AND)" or parentText == "(OR)"then
							-- Move all selected to a negated subnode
							local newPText 
							if parentText == "(OR)" then
								newPText = "NOT(OR)"
							elseif parentText == "(AND)" then
								newPText = "NOT(AND)" 
							end
							newParent = ob.object.SelTree:AppendItem(parent,newPText)
							for i = 1,#Sel do
								ob.object:CopyTree(Sel[i],newParent)
								ob.object:DelTree(Sel[i])
							end
						elseif parentText == "NOT(AND)" then
							ob.object.SelTree:SetItemText(parent,"(AND)")
						elseif parentText == "NOT(OR)" then
							ob.object.SelTree:SetItemText(parent,"(OR)")
						end
						-- Now add the unit to the parent
						if ob.button == "NANDN" or ob.button == "NORN" then
							local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
							ob.object.SelTree:AppendItem(currNode,unit)
						else
							ob.object.SelTree:AppendItem(parent,unit)
						end
					end
					added = true
				end
			end		-- if #Sel < ob.object.SelTree:GetChildrenCount(parent) then ends
			if not added then
				-- Move all selected to sub node
				local parentText = ob.object.SelTree:GetItemText(parent)
				if parentText == "(OR)" or parentText == "NOT(OR)" then
					parentText = "(OR)"
				elseif parentText == "(AND)" or parentText == "NOT(AND)" then
					parentText = "(AND)" 
				end
				parent = ob.object.SelTree:AppendItem(ob.object.SelTree:GetItemParent(Sel[1]),parentText)
				for i = 1,#Sel do
					ob.object:CopyTree(Sel[i],parent)
					ob.object:DelTree(Sel[i])
				end
				Sel = {parent}
			end
		end
		if not added then
			-- Single item selection case
			-- Check if this is a logic node and the unit can directly be added to it
			local selText = ob.object.SelTree:GetItemText(Sel[1])
			if selText == "(OR)" and (ob.button == "OR" or ob.button == "NOR") then
				if ob.button == "OR" then
					-- Add to parent directly
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					-- Add to parent by negating first
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
			elseif  selText == "(AND)" and (ob.button == "AND" or ob.button == "NAND") then
				if ob.button == "AND" then
					-- Add to parent directly
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					-- Add to parent by negating first
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
			elseif selText == "NOT(OR)" and (ob.button == "ORN" or ob.button == "NORN") then
				if ob.button == "ORN" then
					-- Add to parent directly
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					-- Add to parent by negating first
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
				ob.object.SelTree:SetItemText(Sel[1],"(OR)")
			elseif selText == "NOT(AND)" and (ob.button == "ANDN" or ob.button == "NANDN") then
				if ob.button == "ANDN" then
					-- Add to parent directly
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					-- Add to parent by negating first
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
				ob.object.SelTree:SetItemText(Sel[1],"(AND)")
			elseif selText == "NOT()" and (ob.button == "ANDN" or ob.button == "NANDN" or ob.button == "ORN" or ob.button == "NORN")then
				if ob.button == "ANDN" then
					ob.object.SelTree:SetItemText(Sel[1],"(AND)")
					ob.object.SelTree:AppendItem(Sel[1],unit)
				elseif ob.button == "NANDN" then
					ob.object.SelTree:SetItemText(Sel[1],"(AND)")
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				elseif ob.button == "ORN" then
					ob.object.SelTree:SetItemText(Sel[1],"(OR)")
					ob.object.SelTree:AppendItem(Sel[1],unit)
				else
					ob.object.SelTree:SetItemText(Sel[1],"(OR)")
					local currNode = ob.object.SelTree:AppendItem(Sel[1],"NOT()")
					ob.object.SelTree:AppendItem(currNode,unit)
				end
			else
				-- Unit cannot be added to the selected node since that is also a unit
				local parent = ob.object.SelTree:GetItemParent(Sel[1])
				local parentText = ob.object.SelTree:GetItemText(parent)
				-- Handle the directly adding unit to parent cases
				if (parentText == "(OR)" or parentText == "NOT(OR)") and  (ob.button == "OR" or ob.button == "NOR") then
					if ob.button == "OR" then
						-- Add to parent directly
						ob.object.SelTree:AppendItem(parent,unit)
					else
						-- Add to parent by negating first
						local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
						ob.object.SelTree:AppendItem(currNode,unit)
					end
				elseif (parentText == "(AND)" or parentText == "NOT(AND)") and (ob.button == "AND" or ob.button == "NAND") then
					if ob.button == "AND" then
						-- Add to parent directly
						ob.object.SelTree:AppendItem(parent,unit)
					else
						-- Add to parent by negating first
						local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
						ob.object.SelTree:AppendItem(currNode,unit)
					end
				elseif parentText == "NOT()" and (ob.button == "AND" or ob.button == "NAND" or ob.button == "OR" or ob.button == "NOR") then
					-- parentText = "NOT()"
					-- Change Parent text
					if ob.button == "NAND" or ob.button == "AND" then
						ob.object.SelTree:SetItemText(parent,"NOT(AND)")
						if ob.button == "AND" then
							-- Add to parent directly
							ob.object.SelTree:AppendItem(parent,unit)
						else
							-- Add to parent by negating first
							local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
							ob.object.SelTree:AppendItem(currNode,unit)
						end
					elseif ob.button=="NOR" or ob.button == "OR" then
						ob.object.SelTree:SetItemText(parent,"NOT(OR)")
						if ob.button == "OR" then
							-- Add to parent directly
							ob.object.SelTree:AppendItem(parent,unit)
						else
							-- Add to parent by negating first
							local currNode = ob.object.SelTree:AppendItem(parent,"NOT()")
							ob.object.SelTree:AppendItem(currNode,unit)
						end
					end
				else
					-- Now we need to move this single selected node to a new fresh node in its place and add unit also to that node
					if ob.button == "AND" or ob.button == "NAND" or ob.button == "ANDN" or ob.button == "NANDN" then
						parentText = "(AND)"
					elseif ob.button == "OR" or ob.button == "NOR" or ob.button == "ORN" or ob.button == "NORN" then
						parentText = "(OR)"
					end
					local currNode = ob.object.SelTree:AppendItem(parent,parentText)
					if ob.button == "ANDN" or ob.button =="NANDN" or ob.button == "ORN" or ob.button == "NORN" then
						local negNode = ob.object.SelTree:AppendItem(currNode,"NOT()")
						ob.object:CopyTree(Sel[1],negNode)
					else 
						ob.object:CopyTree(Sel[1],currNode)
					end		
					ob.object:DelTree(Sel[1])
					-- Add the unit
					if ob.button == "AND" or ob.button == "OR" or ob.button == "ANDN" or ob.button == "ORN" then
						-- Add to parent directly
						ob.object.SelTree:AppendItem(currNode,unit)
					else
						-- Add to parent by negating first
						local negNode = ob.object.SelTree:AppendItem(currNode,"NOT()")
						ob.object.SelTree:AppendItem(negNode,unit)
					end
				end		-- if (parentText == "(OR)" or parentText == "NOT(OR)") and  (ob.button == "OR" or ob.button == "NOR") then ends
			end		-- if selText == "(OR)" and (ob.button == "OR" or ob.button == "NOR") then ends
		end	-- if not added then ends
		--print(ob.object,ob.button)
		print(BooleanTreeCtrl.BooleanExpression(ob.object.SelTree))	
	end,
	
	TreeSelChanged = function(event)
		setfenv(1,package.loaded[modname])
		local o = BooleanTreeCtrl[event:GetId()]
        
        -- Update the Delete Button status
        local Sel = o.SelTree:GetSelections(Sel)
        if #Sel == 0 then
        	o.prevSel = {}
        	o.DeleteButton:Disable()
        	return nil
        end
        o.DeleteButton:Enable(true)
    	-- Check here if there are more than 1 difference between Sel and prevSel
    	local diff = 0
    	for i = 1,#Sel do
    		local found = nil
    		for j = 1,#o.prevSel do
    			if Sel[i]:GetValue() == o.prevSel[j]:GetValue() then
    				found = true
    				break
    			end
    		end
    		if not found then
    			diff = diff + 1
    		end
    	end
    	-- diff has number of elements in Sel but nout found in o.prevSel
    	for i = 1,#o.prevSel do
    		local found = nil
    		for j = 1,#Sel do
    			if Sel[j]:GetValue() == o.prevSel[i]:GetValue() then
    				found = true
    				break
    			end
    		end
    		if not found then
    			diff = diff + 1
    		end
    	end
        if #Sel > 1 and diff == 1 then
        	-- Check here if the selection needs to be modified to keep at the same level
        	local parent = o.SelTree:GetItemParent(Sel[1])
        	for i = 2,#Sel do
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
        			-- Need to modify the selection here
        			-- Find which element was selected last here
        			local newElem = nil
        			for j = 1,#Sel do
        				local found = nil
        				for k = 1,#o.prevSel do
        					if Sel[j]:GetValue() == o.prevSel[k]:GetValue() then
        						found = true
        						break
        					end
        				end
        				if not found then
        					newElem = Sel[j]
        					break
        				end
        			end		-- for j = 1,#Sel do ends
        			-- Now newElem has the newest element so deselect everything and select that
        			for j = 1,#Sel do
        				o.SelTree:SelectItem(Sel[j],false)
        			end
        			o.SelTree:SelectItem(newElem,true)
	        		Sel = o.SelTree:GetSelections(Sel)
					o.prevSel = {}
					for i = 1,#Sel do
						o.prevSel[i] = Sel[i]
					end
        			break
        		end		-- if o.SelTree:GetItemParent(Sel[i]) ~= parent then ends
        	end		-- for i = 2,#Sel do ends
        end		-- if #Sel > 1 then
--        if #Sel > 1 or o.SelTree:ItemHasChildren(Sel[1]) then
--        	o.DeleteButton:Disable()
--        else
--        	o.DeleteButton:Enable(true)
--        end
		-- Populate prevSel table
    	if diff == 1 and math.abs(#Sel-#o.prevSel) == 1 then
			o.prevSel = {}
			for i = 1,#Sel do
				o.prevSel[i] = Sel[i]
			end
		elseif diff > 1 and math.abs(#Sel-#o.prevSel) == diff then
			-- Selection made by Shift Key check if at same hierarchy then update prevSel otherwise rever to prevSel
        	local parent = o.SelTree:GetItemParent(Sel[1])
        	local updatePrev = true
        	for i = 2,#Sel do
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
        			-- Now newElem has the newest element so deselect everything and select that
        			for j = 1,#Sel do
        				o.SelTree:SelectItem(Sel[j],false)
        			end
        			for j = 1,#o.prevSel do
        				o.SelTree:SelectItem(o.prevSel[j],true)
        			end
        			updatePrev = false
        			break
        		end		-- if o.SelTree:GetItemParent(Sel[i]) ~= parent then ends
        	end		-- for i = 2,#Sel do ends	
        	if updatePrev then		
				o.prevSel = {}
				for i = 1,#Sel do
					o.prevSel[i] = Sel[i]
				end
			end
		end
		
		--event:Skip()
		--print(o.SelTree:GetItemText(item))
	end,
	
	new = function(parent,sizer,getInfoFunc, filterIndex)
		if not parent or not sizer or not getInfoFunc or type(getInfoFunc)~="function" then
			return nil
		end
		local o = {}
		setmetatable(o,BooleanTreeCtrl)
		o.getInfo = getInfoFunc
		o.filterIndex = filterIndex
		o.prevSel = {}
		local ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local ID = NewID()
			o.ANDButton = wx.wxButton(parent, ID, "AND", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			BooleanTreeCtrl[ID] = {object=o,button="AND"}
			ButtonSizer:Add(o.ANDButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.ORButton = wx.wxButton(parent, ID, "OR", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			BooleanTreeCtrl[ID] = {object=o,button="OR"}
			ButtonSizer:Add(o.ORButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.NANDButton = wx.wxButton(parent, ID, "NOT() AND", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			BooleanTreeCtrl[ID] = {object=o,button="NAND"}
			ButtonSizer:Add(o.NANDButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.NORButton = wx.wxButton(parent, ID, "NOT () OR", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			BooleanTreeCtrl[ID] = {object=o,button="NOR"}
			ButtonSizer:Add(o.NORButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.ANDNButton = wx.wxButton(parent, ID, "AND NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			BooleanTreeCtrl[ID] = {object=o,button="ANDN"}
			ButtonSizer:Add(o.ANDNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.ORNButton = wx.wxButton(parent, ID, "OR NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			BooleanTreeCtrl[ID] = {object=o,button="ORN"}
			ButtonSizer:Add(o.ORNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.NANDNButton = wx.wxButton(parent, ID, "NOT() AND NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			BooleanTreeCtrl[ID] = {object=o,button="NANDN"}
			ButtonSizer:Add(o.NANDNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ID = NewID()
			o.NORNButton = wx.wxButton(parent, ID, "NOT() OR NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			BooleanTreeCtrl[ID] = {object=o,button="NORN"}
			ButtonSizer:Add(o.NORNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local treeSizer = wx.wxBoxSizer(wx.wxVERTICAL)
				ID = NewID()
				o.SelTree = wx.wxTreeCtrl(parent, ID, wx.wxDefaultPosition, wx.wxSize(0.1*GUI.initFrameW, 0.1*GUI.initFrameH),bit.bor(wx.wxTR_HAS_BUTTONS,wx.wxTR_MULTIPLE))
				BooleanTreeCtrl[ID] = o
				-- Add the root
				local root = o.SelTree:AddRoot("Expressions")
				o.SelTree:SelectItem(root)
			treeSizer:Add(o.SelTree, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				-- Add the Delete and Negate Buttons
				ButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
					ID = NewID()
					o.DeleteButton = wx.wxButton(parent, ID, "Delete", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					BooleanTreeCtrl[ID] = {object=o,button="Delete"}
				ButtonSizer:Add(o.DeleteButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				o.DeleteButton:Disable()
					ID = NewID()
					o.NegateButton = wx.wxButton(parent, ID, "Negate", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
					BooleanTreeCtrl[ID] = {object=o,button="Negate"}
				ButtonSizer:Add(o.NegateButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			treeSizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)		
		sizer:Add(treeSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	
		-- Connect the buttons to the event handlers
		o.ANDButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.LogicPress)
		o.ORButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.LogicPress)
		o.NANDButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.LogicPress)
		o.NORButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.LogicPress)
		o.ANDNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.LogicPress)
		o.ORNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.LogicPress)
		o.NANDNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.LogicPress)
		o.NORNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.LogicPress)
		o.DeleteButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.DeletePress)
		o.NegateButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,BooleanTreeCtrl.NegatePress)
		
		-- Connect the tree to the left click event
		o.SelTree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, BooleanTreeCtrl.TreeSelChanged)
		
		return o
	end
}		-- BooleanTreeCtrl ends

BooleanTreeCtrl.__index = BooleanTreeCtrl

-- Two List boxes and 2 buttons in between class
MultiSelectCtrl = {
	
	InsertItem = function(ListBox,Item)
		-- Check if the Item exists in the list control
		local itemNum = -1
		while ListBox:GetNextItem(itemNum) ~= -1 do
			local prevItemNum = itemNum
			itemNum = ListBox:GetNextItem(itemNum)
			local itemText = ListBox:GetItemText(itemNum)
			if itemText == Item then
				return true
			end
			if itemText > Item then
				itemNum = prevItemNum
				break
			end 
		end
		-- itemNum contains the item before which to place item
		if itemNum == -1 then
			itemNum = 0
		else 
			itemNum = itemNum + 1
		end
		local newItem = wx.wxListItem()
		newItem:SetId(itemNum)
		newItem:SetText(Item)
		ListBox:InsertItem(newItem)
		return true
	end,
	
	UpdateFilter = function(o)
		local SelList = o.SelList
		local filterIndex = o.filterIndex
		local itemNum = -1
		local str = ""
		while SelList:GetNextItem(itemNum) ~= -1 do
			itemNum = SelList:GetNextItem(itemNum)
			local itemText = SelList:GetItemText(itemNum)
			str = str..itemText..","
		end
		-- Finally Check if none selection box exists
		if o.CheckBox and o.CheckBox:GetValue() then
			str = str..noStr[filterIndex]
		end
		if str ~= "" and string.sub(str,-1,-1) == "," then
			filter[filterIndex]=string.sub(str,1,-2)
		elseif str == "" then
			filter[filterIndex]=nil
		else
			filter[filterIndex]=str
		end
		-- print(filterIndex..": "..tostring(filter[filterIndex]))
	end,
	
	CheckBoxClicked = function(event)
		setfenv(1,package.loaded[modname])
		MultiSelectCtrl.UpdateFilter(MultiSelectCtrl[event:GetId()])
	end,
	
	AddPress = function(event)
		setfenv(1,package.loaded[modname])
		-- Transfer all selected items from List to SelList
		local item
		local o = MultiSelectCtrl[event:GetId()]
		local list = o.List
		local selList = o.SelList
		item = list:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
		local selItems = {}
		while item ~= -1 do
			local itemText = list:GetItemText(item)
			MultiSelectCtrl.InsertItem(selList,itemText)			
			selItems[#selItems + 1] = item	
			item = list:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
		end
		for i=#selItems,1,-1 do
			list:DeleteItem(selItems[i])
		end
		MultiSelectCtrl.UpdateFilter(o)
	end,
	
	RemovePress = function(event)
		setfenv(1,package.loaded[modname])
		-- Transfer all selected items from SelList to List
		local item
		local o = MultiSelectCtrl[event:GetId()]
		local list = o.List
		local selList = o.SelList
		item = selList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
		local selItems = {}
		while item ~= -1 do
			local itemText = selList:GetItemText(item)
			MultiSelectCtrl.InsertItem(list,itemText)			
			selItems[#selItems + 1] = item	
			item = selList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
		end
		for i=#selItems,1,-1 do
			selList:DeleteItem(selItems[i])
		end
		MultiSelectCtrl.UpdateFilter(o)
	end,
	
	new = function(parent, filterIndex, noneSelection, LItems, RItems)
		if not parent then
			return nil
		end
		LItems = LItems or {}
		RItems = RItems or {} 
		local o = {}	-- new object
		setmetatable(o,MultiSelectCtrl)
		o.filterIndex = filterIndex
		-- Create the GUI elements here
		o.Sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)
			o.List = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,bit.bor(wx.wxLC_REPORT,wx.wxLC_NO_HEADER))
			-- Add Items
			local col = wx.wxListItem()
			col:SetId(0)
			o.List:InsertColumn(0,col)
			for i=1,#LItems do
				MultiSelectCtrl.InsertItem(o.List,LItems[i])
			end
			sizer1:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local ID
			if noneSelection then
				ID = NewID()
				o.CheckBox = wx.wxCheckBox(parent, ID, "None Also passes", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				MultiSelectCtrl[ID] = o 
				sizer1:Add(o.CheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			end
			o.Sizer:Add(sizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)
				ID = NewID()
				o.AddButton = wx.wxButton(parent, ID, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				ButtonSizer:Add(o.AddButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				MultiSelectCtrl[ID] = o 
				ID = NewID()
				o.RemoveButton = wx.wxButton(parent, ID, "<", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				ButtonSizer:Add(o.RemoveButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				MultiSelectCtrl[ID] = o
			o.Sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			o.SelList = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,bit.bor(wx.wxLC_REPORT,wx.wxLC_NO_HEADER))
			-- Add Items
			col = wx.wxListItem()
			col:SetId(0)
			o.SelList:InsertColumn(0,col)
			for i=1,#RItems do
				MultiSelectCtrl.InsertItem(o.SelList,RItems[i])
			end
			o.Sizer:Add(o.SelList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		-- Connect the buttons to the event handlers
		o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,MultiSelectCtrl.AddPress)
		o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,MultiSelectCtrl.RemovePress)
		if noneSelection then
			o.CheckBox:Connect(wx. wxEVT_COMMAND_CHECKBOX_CLICKED,MultiSelectCtrl.CheckBoxClicked)
		end
		return o
	end
}		-- MultiSelectCtrl ends

MultiSelectCtrl.__index = MultiSelectCtrl
