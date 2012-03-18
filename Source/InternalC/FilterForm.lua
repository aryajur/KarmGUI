-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application Criteria Entry form UI creation and handling file
-- Author:      Milind Gupta
-- Created:     2/09/2012
-----------------------------------------------------------------------------
local prin
if Globals.__DEBUG then
	prin = print
end
local print = prin 
local wx = wx
local io = io
local wxaui = wxaui
local bit = bit
local GUI = GUI
local tostring = tostring
local loadfile = loadfile
local setfenv = setfenv
local string = string
local Globals = Globals
local setmetatable = setmetatable
local NewID = NewID
local type = type
local math = math
local error = error
local modname = ...
local MainFilter = Filter
local compareDateRanges = compareDateRanges
local combineDateRanges = combineDateRanges
local addItemToArray = addItemToArray
local tableToString = tableToString
local pairs = pairs
local SporeData = SporeData
module(modname)

--local modname = ...

--M = {}
--package.loaded[modname] = M
--setmetatable(M,{["__index"]=_G})
--setfenv(1,M)

-- Local filter table to store the filter criteria
filter = {}

noStr = {
	Cat = Globals.NoCatStr,
	SubCat = Globals.NoSubCatStr,
	Priority = Globals.NoPriStr,
	Due = Globals.NoDateStr,
	Fin = Globals.NoDateStr,
	ScheduleRange = Globals.NoDateStr,
	Tags = Globals.NoTagStr,
	Access = Globals.NoAccessIDStr
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
end		-- local function SelTaskPress(event) ends

local function loadFilter(event)
	setfenv(1,package.loaded[modname])
	local ValidFilter = function(file)
		local safeenv = {}
		local f,message = loadfile(file)
		if not f then
			return nil,message
		end
		setfenv(f,safeenv)
		f()
		if safeenv.filter and type(safeenv.filter) == "table" then
			return safeenv.filter
		else
			return nil,"Cannot find a valid filter in the file."
		end
	end
    local fileDialog = wx.wxFileDialog(frame, "Open file",
                                       "",
                                       "",
                                       "Karm Filter files (*.kff)|*.kff|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
    	local result,message = ValidFilter(fileDialog:GetPath())
        if not result then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.\n "..message,
                            "File Load Error",
                            wx.wxOK + wx.wxCENTRE, frame)
        else
        	SetFilter(result)
        end
    end
    fileDialog:Destroy()
end

local function saveFilter(event)
	setfenv(1,package.loaded[modname])
    local fileDialog = wx.wxFileDialog(frame, "Save File",
                                       "",
                                       "",
                                       "Karm Filter files (*.kff)|*.kff|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxFD_SAVE)
    if fileDialog:ShowModal() == wx.wxID_OK then
    	local file,err = io.open(fileDialog:GetPath(),"w+")
    	if not file then
            wx.wxMessageBox("Unable to save as file '"..fileDialog:GetPath().."'.\n "..err,
                            "File Save Error",
                            wx.wxOK + wx.wxCENTRE, frame)
        else
        	file:write(tableToString(filter))
        	file:close()
        end
    end
    fileDialog:Destroy()

end

local function initializeFilterForm(filterData)
	-- Clear Task Selection
	FilterTask:SetLabel("No Task Selected")
	-- Clear Category
	CatCtrl:ResetCtrl()
	-- Clear Sub-Category
	SubCatCtrl:ResetCtrl()
	-- Clear Priority
	PriCtrl:ResetCtrl()
	-- Clear Status
	StatCtrl:ResetCtrl()
	-- Clear Tags List
	TagList:DeleteAllItems()
	TagBoolCtrl:ResetCtrl()
	-- Clear Dates
	dateStarted:ResetCtrl()
	dateFinished:ResetCtrl()
	dateDue:ResetCtrl()
	-- Who and Access
	whoCtrl:ResetCtrl()
	WhoBoolCtrl:ResetCtrl()
	accCtrl:ResetCtrl()
	accBoolCtrl:ResetCtrl()
	-- Schedules
	schDateRanges:ResetCtrl()
	SchBoolCtrl:ResetCtrl()
	filter = {}		-- Clear the filter
end

function filterFormActivate(parent)
	-- Accumulate Filter Data across all spores
	local filterData = {}
	-- Loop through all the spores
	for k,v in pairs(SporeData) do
		if k~=0 then
			for ki,val in pairs(v.filterData) do
				-- Collect Data
				filterData[ki] = {}
				for i = 1,#v.filterData[ki] do
					addItemToArray(v.filterData[ki][i],filterData[ki]) 
				end
			end
		end		-- if k~=0 then ends
	end		-- for k,v in pairs(SporeData) do ends
	
	frame = wx.wxFrame(parent, wx.wxID_ANY, "Filter Form", wx.wxDefaultPosition,
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	-- Create tool bar
	ID_LOAD = NewID()
	ID_SAVE = NewID()
	local toolBar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
	local toolBmpSize = toolBar:GetToolBitmapSize()

	toolBar:AddTool(ID_LOAD, "Load", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DIR_UP, wx.wxART_MENU, toolBmpSize), "Load Filter Criteria")
	toolBar:AddTool(ID_SAVE, "Save", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize), "Save Filter Criteria")
	toolBar:Realize()
	
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)

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
				CatCtrl = MultiSelectCtrl.new(TandC,"Cat",true,filterData.Cat)
				--CatCtrl.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,MultiSelectCtrl.AddPress)
				TandCSizer:Add(CatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				SubCategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, "Select Sub-Categories", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				TandCSizer:Add(SubCategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				-- Sub Category Listboxes and Buttons
				SubCatCtrl = MultiSelectCtrl.new(TandC,"SubCat",true,filterData.SubCat)
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
				PriCtrl = MultiSelectCtrl.new(PSandTag,"Priority",true,filterData.Priority)
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
					--local col = wx.wxListItem()
					--col:SetId(0)
					TagList:InsertColumn(0,"Tags")
					if filterData.Tags then
						for i=1,#filterData.Tags do
							MultiSelectCtrl.InsertItem(TagList,filterData.Tags[i])
						end
					end
					
					TagSizer:Add(TagList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					TagBoolCtrl = BooleanTreeCtrl.new(PSandTag,TagSizer,
						function()
							-- Return the selected item in Tag List
							local item = TagList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
							if item == -1 then
								return nil
							else 
								return TagList:GetItemText(item)		
							end
						end, 
					"Tags")
				PSandTagSizer:Add(TagSizer, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			PSandTag:SetSizer(PSandTagSizer)
			PSandTagSizer:SetSizeHints(PSandTag)
		MainBook:AddPage(PSandTag, "Priorities,Status and Tags")
		
		-- Date Started, Date Finished and Due Date Page
		DatesPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local DatesPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) 
			
			-- Date Started Control
			dateStarted = DateRangeCtrl.new(DatesPanel,"Start",false,"Date Started")
			DatesPanelSizer:Add(dateStarted.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			-- Date Finished Control
			dateFinished = DateRangeCtrl.new(DatesPanel,"Fin",true,"Date Finished")
			DatesPanelSizer:Add(dateFinished.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			-- Due Date Control
			dateDue = DateRangeCtrl.new(DatesPanel,"Due",true,"Due Date")
			DatesPanelSizer:Add(dateDue.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			

			DatesPanel:SetSizer(DatesPanelSizer)
			DatesPanelSizer:SetSizeHints(DatesPanel)
		MainBook:AddPage(DatesPanel, "Dates:Due,Started,Finished")

		-- Who and Access IDs page
		AccessPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local AccessPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			
			local whoSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local accSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) 
			
			local whoLabel = wx.wxStaticText(AccessPanel, wx.wxID_ANY, "Select Responsible People (Check means Inactive)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			AccessPanelSizer:Add(whoLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			
			whoCtrl = CheckListCtrl.new(AccessPanel,false,"I","A")
			-- Populate the IDs
			for i = 1,#filterData.Who do
				whoCtrl.InsertItem(whoCtrl.List,filterData.Who[i], false)
			end
			whoSizer:Add(whoCtrl.Sizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			WhoBoolCtrl = BooleanTreeCtrl.new(AccessPanel,whoSizer,whoCtrl:getSelectionFunc(), "Who")
			AccessPanelSizer:Add(whoSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			
			local accLabel = wx.wxStaticText(AccessPanel, wx.wxID_ANY, "Select People for access (Check means Read/Write Access)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			AccessPanelSizer:Add(accLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			accCtrl = CheckListCtrl.new(AccessPanel,false,"W","R")
			-- Populate the IDs
			if filterData.Access then
				for i = 1,#filterData.Access do
					accCtrl.InsertItem(accCtrl.List,filterData.Access[i], false)
				end
			end
			accSizer:Add(accCtrl.Sizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			accBoolCtrl = BooleanTreeCtrl.new(AccessPanel,accSizer,accCtrl:getSelectionFunc(), "Access")
			AccessPanelSizer:Add(accSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)

			AccessPanel:SetSizer(AccessPanelSizer)
			AccessPanelSizer:SetSizeHints(AccessPanel)
		MainBook:AddPage(AccessPanel, "Access")
		
		-- Schedules Page
		SchPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local SchPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) 
			local duSizer = wx.wxBoxSizer(wx.wxVERTICAL)	-- Sizer for Date unit elements
			
			local typeMatchLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, "Select Type of Matching", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			duSizer:Add(typeMatchLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			TypeMatch = wx.wxChoice(SchPanel, wx.wxID_ANY,wx.wxDefaultPosition, wx.wxDefaultSize,{"Full","Overlap"})
			duSizer:Add(TypeMatch,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			TypeMatch:SetSelection(1)
			
			local typeSchLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, "Select Type of Schedule", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			duSizer:Add(typeSchLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			TypeSch = wx.wxChoice(SchPanel, wx.wxID_ANY,wx.wxDefaultPosition, wx.wxDefaultSize,{"Estimate","Committed","Revisions","Actual"})
			duSizer:Add(TypeSch,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			TypeSch:SetSelection(2)
						
			local SchRevLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, "Select Revision", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			duSizer:Add(SchRevLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

			SchRev = wx.wxComboBox(SchPanel, wx.wxID_ANY,"Latest",wx.wxDefaultPosition, wx.wxDefaultSize,{"Latest"})
			duSizer:Add(SchRev,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)

			-- Event connect to enable disable SchRev
			TypeSch:Connect(wx.wxEVT_COMMAND_CHOICE_SELECTED,function(event) 
				setfenv(1,package.loaded[modname])
				if TypeSch:GetString(TypeSch:GetSelection()) == "Estimate" or TypeSch:GetString(TypeSch:GetSelection()) == "Revisions" then
					SchRev:Enable(true)
				else
					SchRev:Enable(false)
				end
			end 
			)

			local DateRangeLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, "Select Date Ranges", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			duSizer:Add(DateRangeLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			-- Date Ranges Control
			schDateRanges = DateRangeCtrl.new(SchPanel,"ScheduleRange",true,"Date Ranges") 
			duSizer:Add(schDateRanges.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			
			SchPanelSizer:Add(duSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)

			-- Now add the Boolean Control
			local getSchUnit = function()
				-- Get the full schedule boolean unit
				local unit = TypeMatch:GetString(TypeMatch:GetSelection())..","..TypeSch:GetString(TypeSch:GetSelection())
				if SchRev:IsEnabled() then
					if SchRev:GetValue() == "Latest" then
						unit = unit.."(L)"
					else
						unit = unit.."("..tostring(SchRev:GetValue())..")"
					end
				end
				unit = unit..","..filter.ScheduleRange
				return unit
			end 

			SchBoolCtrl = BooleanTreeCtrl.new(SchPanel,SchPanelSizer,getSchUnit, "Schedules")

			

			SchPanel:SetSizer(SchPanelSizer)
			SchPanelSizer:SetSizeHints(SchPanel)
		MainBook:AddPage(SchPanel, "Schedules")

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
	--MainSizer:SetSizeHints(frame)
	
	-- Connect event handlers to the buttons
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function (event)
			setfenv(1,package.loaded[modname])		
			frame:Close()
		end
	)
	
	ApplyButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			print(tableToString(filter))
			MainFilter = filter
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

	-- Toolbar button events
	frame:Connect(ID_LOAD,wx.wxEVT_COMMAND_MENU_SELECTED,loadFilter)
	frame:Connect(ID_SAVE,wx.wxEVT_COMMAND_MENU_SELECTED,saveFilter)
	
    frame:Layout() -- help sizing the windows before being shown
    frame:Show(true)
    initializeFilterForm(filterData)
end		-- function filterFormActivate(parent) ends


-- Object to generate and manage a check list 
CheckListCtrl = {
	getSelectionFunc = function(obj)
		-- Return the selected item in List
		local o = obj		-- Declare an upvalue
		return function()
			local itemNum = o.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			if itemNum == -1 then
				return nil
			else 
				local str
				local item = wx.wxListItem()
				item:SetId(itemNum)
				item:SetMask(wx.wxLIST_MASK_IMAGE)
				o.List:GetItem(item)
				if item:GetImage() == 0 then
					-- Item checked
					str = o.checkedText
				else
					-- Item Unchecked
					str = o.uncheckedText
				end
				item:SetId(itemNum)
				item:SetColumn(1)
				item:SetMask(wx.wxLIST_MASK_TEXT)
				o.List:GetItem(item)
				str = item:GetText()..","..str
				return str	
			end
		end
	end,
	
	InsertItem = function(ListBox,Item,checked)
		-- Check if the Item exists in the list control
		local itemNum = -1
		-- print(ListBox:GetNextItem(itemNum))
		while ListBox:GetNextItem(itemNum) ~= -1 do
			local prevItemNum = itemNum
			itemNum = ListBox:GetNextItem(itemNum)
			local obj = wx.wxListItem()
			obj:SetId(itemNum)
			obj:SetColumn(1)
			obj:SetMask(wx.wxLIST_MASK_TEXT)
			ListBox:GetItem(obj)
			local itemText = obj:GetText()
			if itemText == Item then
				-- Get checked status and update
				if checked then
					itemNum:SetImage(0)
				else
					itemNum:SetImage(1)
				end				
				return true
			end
			if itemText > Item then
				itemNum = prevItemNum
				break
			end 
		end
		-- itemNum contains the item after which to place item
		if itemNum == -1 then
			itemNum = 0
		else 
			itemNum = itemNum + 1
		end
		local newItem = wx.wxListItem()
		local img
		newItem:SetId(itemNum)
		--newItem:SetText(Item)
		if checked then
			newItem:SetImage(0)
		else
			newItem:SetImage(1)
		end				
		--newItem:SetTextColour(wx.wxColour(wx.wxBLACK))
		ListBox:InsertItem(newItem)
		ListBox:SetItem(itemNum,1,Item)
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)		
		ListBox:SetColumnWidth(1,wx.wxLIST_AUTOSIZE)		
		return true
	end,

	new = function(parent,noneSelection,checkedText,uncheckedText)
		if not parent then
			return nil
		end
		local o = {}	-- new object
		setmetatable(o,CheckListCtrl)
		o.Sizer = wx.wxBoxSizer(wx.wxVERTICAL)
		o.checkedText = checkedText
		o.uncheckedText = uncheckedText
		local ID
		ID = NewID()		
		o.List = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_SINGLE_SEL+wx.wxLC_NO_HEADER)
		CheckListCtrl[ID] = o
		-- Create the imagelist and add check and uncheck icons
		local imageList = wx.wxImageList(16,16,true,0)
		local icon = wx.wxIcon()
		icon:LoadFile("images/checked.xpm",wx.wxBITMAP_TYPE_XPM)
		imageList:Add(icon)
		icon:LoadFile("images/unchecked.xpm",wx.wxBITMAP_TYPE_XPM)
		imageList:Add(icon)
		o.List:SetImageList(imageList,wx.wxIMAGE_LIST_SMALL)
		-- Add Items
		o.List:InsertColumn(0,"Check")
		o.List:InsertColumn(1,"Options")
		--[[CheckListCtrl.InsertItem(o.List,"A", true)
		CheckListCtrl.InsertItem(o.List,"C", false)
		CheckListCtrl.InsertItem(o.List,"B", true)]]
		o.Sizer:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		o.List:Connect(wx.wxEVT_COMMAND_LIST_ITEM_RIGHT_CLICK, CheckListCtrl.RightClick)
		return o
	end,
	
	ResetCtrl = function(o)
		o.List:DeleteAllItems()
	end,

	RightClick = function(event)
		setfenv(1,package.loaded[modname])
		local o = CheckListCtrl[event:GetId()]
		--o.List:SetImageList(o.mageList,wx.wxIMAGE_LIST_SMALL)
		local item = wx.wxListItem()
		local itemNum = event:GetIndex()
		item:SetId(itemNum)
		item:SetMask(wx.wxLIST_MASK_IMAGE)
		o.List:GetItem(item)
		if item:GetImage() == 0 then
			--item:SetImage(1)
			o.List:SetItemColumnImage(item:GetId(),0,1)
		else
			--item:SetImage(0)
			o.List:SetItemColumnImage(item:GetId(),0,0)
		end
		event:Skip()
	end
}	-- CheckListCtrl ends
CheckListCtrl.__index = CheckListCtrl

-- Control to select date Range

SelectDateRangeCtrl = {
	display = function(parent,numInstances,returnFunc)
		if not SelectDateRangeCtrl[parent] then
			SelectDateRangeCtrl[parent] = 1
		elseif SelectDateRangeCtrl[parent] >= numInstances then
			return false
		else
			SelectDateRangeCtrl[parent] = SelectDateRangeCtrl[parent] + 1
		end
		local drFrame = wx.wxFrame(parent, wx.wxID_ANY, "Date Range Selection", wx.wxDefaultPosition,
			wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION
			+ wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN)
		local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		local calSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
		local fromSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		local label = wx.wxStaticText(drFrame, wx.wxID_ANY, "From:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		fromSizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		local fromDate = wx.wxCalendarCtrl(drFrame,wx.wxID_ANY)
		fromSizer:Add(fromDate, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

		local toSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		label = wx.wxStaticText(drFrame, wx.wxID_ANY, "To:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		toSizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		local toDate = wx.wxCalendarCtrl(drFrame,wx.wxID_ANY)
		toSizer:Add(toDate, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		
		calSizer:Add(fromSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		calSizer:Add(toSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		
		-- Add Buttons
		local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
		local selButton = wx.wxButton(drFrame, wx.wxID_ANY, "Select", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		buttonSizer:Add(selButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		local CancelButton = wx.wxButton(drFrame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		buttonSizer:Add(CancelButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		
		
		MainSizer:Add(calSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		drFrame:SetSizer(MainSizer)
		MainSizer:SetSizeHints(drFrame)
	    drFrame:Layout() -- help sizing the windows before being shown
	    drFrame:Show(true)
	    
		selButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,function(event)
			setfenv(1,package.loaded[modname])
			returnFunc(fromDate:GetDate():Format("%m/%d/%Y").."-"..toDate:GetDate():Format("%m/%d/%Y"))
			drFrame:Close()
			SelectDateRangeCtrl[parent] = SelectDateRangeCtrl[parent] - 1
		end	
		)
		CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,function(event)
			setfenv(1,package.loaded[modname])
			drFrame:Close() 
			SelectDateRangeCtrl[parent] = SelectDateRangeCtrl[parent] - 1
		end
		)	    	
	end		-- display = function(parent,numInstances,returnFunc) ends
}		-- SelectDateRangeCtrl ends

-- Date Range Selection Control
DateRangeCtrl = {
	new = function(parent, filterIndex, noneSelection, heading)
		-- parent is a wxPanel
		if not parent then
			return nil
		end
		local o = {}	-- new object
		setmetatable(o,DateRangeCtrl)
		o.filterIndex = filterIndex
		o.parent = parent
		-- Create the GUI elements here
		o.Sizer = wx.wxBoxSizer(wx.wxVERTICAL)
		
		-- Heading
		local label = wx.wxStaticText(parent, wx.wxID_ANY, heading, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		o.Sizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		
		-- List Control
		local ID
		ID = NewID()
		o.list = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
		o.list:InsertColumn(0,"Ranges")
		DateRangeCtrl[ID] = o 
		o.list:InsertColumn(0,heading)
		o.Sizer:Add(o.list, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		
		-- none Selection check box
		if noneSelection then
			ID = NewID()
			o.CheckBox = wx.wxCheckBox(parent, ID, "None Also passes", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			DateRangeCtrl[ID] = o 
			o.Sizer:Add(o.CheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		end
		
		-- Add Date Range Button
		ID = NewID()
		o.AddButton = wx.wxButton(parent, ID, "Add Range", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		o.Sizer:Add(o.AddButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		DateRangeCtrl[ID] = o 

		-- Remove Date Range Button
		ID = NewID()
		o.RemoveButton = wx.wxButton(parent, ID, "Remove Range", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		o.Sizer:Add(o.RemoveButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		DateRangeCtrl[ID] = o 
		o.RemoveButton:Disable()
		
		-- Clear Date Ranges Button
		ID = NewID()
		o.ClearButton = wx.wxButton(parent, ID, "Clear Ranges", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
		o.Sizer:Add(o.ClearButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
		DateRangeCtrl[ID] = o 
		
		-- Associate Events
		o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,DateRangeCtrl.AddPress)
		o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,DateRangeCtrl.RemovePress)
		o.ClearButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,DateRangeCtrl.ClearPress)

		o.list:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED,DateRangeCtrl.ListSel)
		o.list:Connect(wx.wxEVT_COMMAND_LIST_ITEM_DESELECTED,DateRangeCtrl.ListSel)
		
		if noneSelection then
			o.CheckBox:Connect(wx. wxEVT_COMMAND_CHECKBOX_CLICKED,DateRangeCtrl.CheckBoxClicked)
		end

		return o
	end,
	
	CheckBoxClicked = function(event)
		setfenv(1,package.loaded[modname])
		DateRangeCtrl.UpdateFilter(DateRangeCtrl[event:GetId()])
	end,
	
	UpdateFilter = function(o)
		-- Update the filter
		local itemNum = -1
		local filterText = ""
		while o.list:GetNextItem(itemNum) ~= -1 do
			itemNum = o.list:GetNextItem(itemNum)
			filterText = filterText..o.list:GetItemText(itemNum)..","
		end
		-- Finally Check if none selection box exists
		if o.CheckBox and o.CheckBox:GetValue() then
			filterText = filterText..noStr[o.filterIndex]
		end
		if filterText ~= "" and string.sub(filterText,-1,-1) == "," then
			filter[o.filterIndex]=string.sub(filterText,1,-2)
		elseif filterText == "" then
			filter[o.filterIndex]=nil
		else
			filter[o.filterIndex]=filterText
		end
	end,
	
	AddPress = function(event)
		setfenv(1,package.loaded[modname])
		local o = DateRangeCtrl[event:GetId()]
	    
	    local addRange = function(range)
			-- Check if the Item exists in the list control
			local itemNum = -1
			local conditionList = false
			while o.list:GetNextItem(itemNum) ~= -1 do
				local prevItemNum = itemNum
				itemNum = o.list:GetNextItem(itemNum)
				local itemText = o.list:GetItemText(itemNum)
				-- Now compare the dateRanges
				local comp = compareDateRanges(range,itemText)
				if comp == 1 then
					-- Ranges are same, do nothing
					drFrame:Close()
					return true
				elseif comp==2 then
					-- range1 lies entirely before range2
					itemNum = prevItemNum
					break
				elseif comp==3 then
					-- comp=3 range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2
					range = combineDateRanges(range,itemText)
					-- Delete the current item
					o.list:DeleteItem(itemNum)
					itemNum = prevItemNum
					break
				elseif comp==4 then
					-- comp=4 range1 lies entirely inside range2
					-- range given is subset, do nothing
					return true
				elseif comp==5 or comp==7 then
					-- comp=5 range1 post overlaps range2
					-- comp=7 range2 lies entirely inside range1
					range = combineDateRanges(range,itemText)
					-- Delete the current item
					o.list:DeleteItem(itemNum)
					itemNum = prevItemNum
					conditionList = true	-- To condition the list to merge any overlapping ranges
					break
				elseif comp==6 then
					-- range1 lies entirely after range2
					-- Do nothing look at next item
				else
					return nil
				end
				--print(range..">"..tostring(comp))
			end
			-- itemNum contains the item after which to place item
			if itemNum == -1 then
				itemNum = 0
			else 
				itemNum = itemNum + 1
			end
			local newItem = wx.wxListItem()
			newItem:SetId(itemNum)
			newItem:SetText(range)
			o.list:InsertItem(newItem)
			o.list:SetItem(itemNum,0,range)
			
			-- Condition the list here if required
			while conditionList and o.list:GetNextItem(itemNum) ~= -1 do
				local prevItemNum = itemNum
				itemNum = o.list:GetNextItem(itemNum)
				local itemText = o.list:GetItemText(itemNum)
				-- Now compare the dateRanges
				local comp = compareDateRanges(range,itemText)
				if comp == 1 then
					-- Ranges are same, delete this itemText range
					o.list:DeleteItem(itemNum)
					itemNum = prevItemNum
				elseif comp==2 then
					 -- range1 lies entirely before range2
					 conditionList = nil
				elseif comp==3 then
					-- comp=3 range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2
					range = combineDateRanges(range,itemText)
					-- Delete the current item
					o.list:DeleteItem(itemNum)
					itemNum = prevItemNum
					o.list:SetItemText(itemNum,range)
					conditionList = nil
				elseif comp==4 then
					-- comp=4 range1 lies entirely inside range2
					error("Code Error: This condition should never occur!",1)
				elseif comp==5 or comp==7 then
					-- comp=5 range1 post overlaps range2
					-- comp=7 range2 lies entirely inside range1
					range = combineDateRanges(range,itemText)
					-- Delete the current item
					o.list:DeleteItem(itemNum)
					itemNum = prevItemNum
					o.list:SetItemText(itemNum,range)
				elseif comp==6 then
					-- range1 lies entirely after range2
					error("Code Error: This condition should never occur!",1)
				else
					error("Code Error: This condition should never occur!",1)
				end				
			end		-- while conditionList and o.list:GetNextItem(itemNum) ~= -1 ends
			o.list:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)
			DateRangeCtrl.UpdateFilter(o)
	    end		-- local addRange = function(range) ends
	    
		-- Create the frame to accept date range
		SelectDateRangeCtrl.display(o.parent,1,addRange)

	end,
	
	RemovePress = function(event)
		setfenv(1,package.loaded[modname])
		local o = DateRangeCtrl[event:GetId()]
		item = o.list:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
		local selItems = {}
		while item ~= -1 do
			selItems[#selItems + 1] = item	
			item = o.list:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
		end
		for i=#selItems,1,-1 do
			o.list:DeleteItem(selItems[i])
		end
		DateRangeCtrl.UpdateFilter(o)
	end,
	
	ClearPress = function(event)
		setfenv(1,package.loaded[modname])
		local o = DateRangeCtrl[event:GetId()]
		o.list:DeleteAllItems()	
		DateRangeCtrl.UpdateFilter(o)
	end,
	
	ResetCtrl = function(o)
		o.list:DeleteAllItems()
		if o.CheckBox then
			o.CheckBox:SetValue(false)
		end
		o:UpdateFilter()
	end,
	
	ListSel = function(event)
		setfenv(1,package.loaded[modname])
		local o = DateRangeCtrl[event:GetId()]
        if o.list:GetSelectedItemCount() == 0 then
			o.RemoveButton:Disable()
        	return nil
        end
		o.RemoveButton:Enable(true)
	end
}		-- DateRangeCtrl ends
DateRangeCtrl.__index = DateRangeCtrl



-- Boolean Tree and Boolean buttons
BooleanTreeCtrl = {

	UpdateFilter = function(o)
		local filterText = BooleanTreeCtrl.BooleanExpression(o.SelTree)
		if filterText == "" then
			filter[o.filterIndex]=nil
		else
			filter[o.filterIndex]=filterText
		end
	end,
	
	BooleanExpression = function(tree)
		local currNode = tree:GetFirstChild(tree:GetRootItem())
		local expr = BooleanTreeCtrl.treeRecurse(tree,currNode)
		return expr		
	end,
	
	treeRecurse = function(tree,node)
		local itemText = tree:GetItemText(node) 
		if itemText == "(AND)" or itemText == "(OR)" or itemText == "NOT(OR)" or itemText == "NOT(AND)" then
			local retText = "(" 
			local logic = string.lower(" "..string.match(itemText,"%((.-)%)").." ")
			if string.sub(itemText,1,3) == "NOT" then
				retText = "not("
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
			return "not("..BooleanTreeCtrl.treeRecurse(tree,tree:GetFirstChild(node))..")"
		else
			return "'"..itemText.."'"
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
	
	ResetCtrl = function(o)
		if o.SelTree:GetFirstChild(o.SelTree:GetRootItem()):IsOk() then
			o:DelTree(o.SelTree:GetFirstChild(o.SelTree:GetRootItem()))
			o:UpdateFilter()
		end
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
			if Sel[i]:GetValue() ~= ob.object.SelTree:GetRootItem():GetValue() then
				ob.object:DelTree(Sel[i])
			end
		end
		if ob.object.SelTree:GetChildrenCount(ob.object.SelTree:GetRootItem()) == 1 then
			ob.object.DeleteButton:Disable()
		end
		ob.object:UpdateFilter()
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
		if parent:IsOk() then
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
			ob.object:UpdateFilter()
		end	-- if parent:IsOk() then
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
		
		-- Check if parent of all selections is the same	
		if #Sel > 1 then
        	local parent = ob.object.SelTree:GetItemParent(Sel[1])
        	for i = 2,#Sel do
        		if ob.object.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
        			-- Parent is not common. 
        			wx.wxMessageBox("All selected items not siblings!","Error applying operation", wx.wxICON_ERROR)
        			return nil
        		end
        	end
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
		--print(BooleanTreeCtrl.BooleanExpression(ob.object.SelTree))	
		ob.object:UpdateFilter()
	end,
	
--[[	TreeSelChanged = function(event)
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
	end,]]
	
	TreeSelChanged = function(event)
		setfenv(1,package.loaded[modname])
		local o = BooleanTreeCtrl[event:GetId()]
        
        -- Update the Delete Button status
        local Sel = o.SelTree:GetSelections(Sel)
        if #Sel == 0 then
        	o.prevSel = {}
        	o.DeleteButton:Disable()
        	o.NegateButton:Disable()
        	return nil
        end
        o.DeleteButton:Enable(true)
       	o.NegateButton:Enable(true)
		-- Check if parent of all selections is the same	
		if #Sel > 1 then
        	local parent = o.SelTree:GetItemParent(Sel[1])
        	for i = 2,#Sel do
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then
        			-- Deselect everything
        			for j = 1,#Sel do
        				o.SelTree:SelectItem(Sel[j],false)
        			end
        			-- Select the items with the largest parent
        			local parents = {}	-- To store parents and their numbers
        			for j =1,#Sel do
        				local found = nil
        				for k = 1,#parents do
        					if o.SelTree:GetItemParent(Sel[j]):GetValue() == parents[k].ID:GetValue() then
        						parents[k].count = parents[k].count + 1
        						found = true
        						break
        					end
        				end
        				if not found then
        					parents[#parents + 1] = {ID = o.SelTree:GetItemParent(Sel[j]), count = 1}
        				end
        			end
        			-- Find parent with largest number of children
        			local index = 1
        			for j = 2,#parents do
        				if parents[j].count > parents[index].count then
        					index = j
        				end
        			end
        			-- Select all items with parents[index].ID as parent
        			for j = 1,#Sel do
        				if o.SelTree:GetItemParent(Sel[j]):GetValue() == parents[index].ID:GetValue() then
        					o.SelTree:SelectItem(Sel[j],true)
        				end
        			end		-- for j = 1,#Sel do ends
        		end		-- if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then ends
        	end		-- for i = 2,#Sel do ends
        end		-- if #Sel > 1 then ends
        event:Skip()
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
			o.NORButton = wx.wxButton(parent, ID, "NOT() OR", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
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
				o.NegateButton:Disable()
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
		-- itemNum contains the item after which to place item
		if itemNum == -1 then
			itemNum = 0
		else 
			itemNum = itemNum + 1
		end
		local newItem = wx.wxListItem()
		newItem:SetId(itemNum)
		newItem:SetText(Item)
		newItem:SetTextColour(wx.wxColour(wx.wxBLACK))
		ListBox:InsertItem(newItem)
		ListBox:SetItem(itemNum,0,Item)
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)
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
	
	ResetCtrl = function(o)
		o.SelList:DeleteAllItems()
		o.List:DeleteAllItems()
		if o.CheckBox then
			o.CheckBox:SetValue(false)
		end
		o:UpdateFilter()
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
			o.List = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
			-- Add Items
			--local col = wx.wxListItem()
			--col:SetId(0)
			o.List:InsertColumn(0,"Options")
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
			o.SelList = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
			-- Add Items
			--col = wx.wxListItem()
			--col:SetId(0)
			o.SelList:InsertColumn(0,"Selections")
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
