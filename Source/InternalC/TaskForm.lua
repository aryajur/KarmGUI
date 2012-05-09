-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application Task Entry form UI creation and handling file
-- Author:      Milind Gupta
-- Created:     4/11/2012
-----------------------------------------------------------------------------

local modname = ...
local wx = wx
local wxaui = wxaui
local setfenv = setfenv
local pairs = pairs
local GUI = GUI
local bit = bit
local Globals = Globals
local XMLDate2wxDateTime = XMLDate2wxDateTime
local task2IncSchTasks = task2IncSchTasks
local getEmptyTask = getEmptyTask
local copyTask = copyTask
local addItemToArray = addItemToArray
local newGUITreeGantt = function() 
		return newGUITreeGantt 
	end

local CW = require("CustomWidgets")


module(modname)

local taskData	-- To store the task data locally
local filterData = {}

local function dateRangeChangeEvent(event)
	setfenv(1,package.loaded[modname])
	local startDate = dateStartPick:GetValue()
	local finDate = dateFinPick:GetValue()
	taskTree:dateRangeChange(startDate,finDate)
	event:Skip()
end

local function dateRangeChange()
	local startDate = dateStartPick:GetValue()
	local finDate = dateFinPick:GetValue()
	taskTree:dateRangeChange(startDate,finDate)
end

function taskFormActivate(parent, SporeData, task, callBack)
	-- Accumulate Filter Data across all spores
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

	frame = wx.wxFrame(parent, wx.wxID_ANY, "Task Form", wx.wxDefaultPosition,
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)

	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
		-- Create the tab book
		MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)
		-- Basic Task Info
		TInfo = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)
				local sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				local textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Title:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				if task and task.Title then
					titleBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, task.Title, wx.wxDefaultPosition, wx.wxDefaultSize)
				else
					titleBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, "Enter Task Title", wx.wxDefaultPosition, wx.wxDefaultSize)
				end				
				sizer2:Add(titleBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					-- Start Date
					local sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Start Date:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					if task and task.Start then
						startDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,XMLDate2wxDateTime(task.Start), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
					else
						startDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
					end					
					sizer3:Add(startDate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					-- Due Date
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Due Date:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					if task and task.Due then
						dueDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,XMLDate2wxDateTime(task.Due), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN+wx.wxDP_ALLOWNONE)
					else
						dueDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN+wx.wxDP_ALLOWNONE)
					end						
					sizer3:Add(dueDate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					-- Priority
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Priority:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					local list = {""}
					for i = 1,#Globals.PriorityList do
						list[i+1] = Globals.PriorityList[i]
					end
					if task and task.Priority then
						priority = wx.wxComboBox(TInfo, wx.wxID_ANY,task.Priority, wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)
					else
						priority = wx.wxComboBox(TInfo, wx.wxID_ANY,"", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)
					end
					sizer3:Add(priority, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					-- Private/Public
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Private/Public:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					list = {"Public","Private"}
					if task and task.Private then
						pubPrivate = wx.wxComboBox(TInfo, wx.wxID_ANY,"Private", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)
					else
						pubPrivate = wx.wxComboBox(TInfo, wx.wxID_ANY,"Public", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)
					end
					sizer3:Add(pubPrivate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					-- Status
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Status:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					if task and task.Status then
						status = wx.wxComboBox(TInfo, wx.wxID_ANY,task.Status, wx.wxDefaultPosition, wx.wxDefaultSize, Globals.StatusList, wx.wxCB_READONLY)
					else
						status = wx.wxComboBox(TInfo, wx.wxID_ANY,Globals.StatusList[1], wx.wxDefaultPosition, wx.wxDefaultSize, Globals.StatusList, wx.wxCB_READONLY)
					end					
					sizer3:Add(status, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
					sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				-- Comment
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
				textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, "Comment:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				if task and task.Comments then
					commentBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, task.Comments, wx.wxDefaultPosition, wx.wxDefaultSize)
				else
					commentBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, "Enter Comment", wx.wxDefaultPosition, wx.wxDefaultSize)
				end
				sizer2:Add(commentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				

				
				TInfo:SetSizer(sizer1)
			sizer1:SetSizeHints(TInfo)
		MainBook:AddPage(TInfo, "Basic Info")				

		-- Classification Page
		TClass = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)

				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, "Category:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					list = {""}
					for i = 1,#Globals.Categories do
						list[i+1] = Globals.Categories[i]
					end
					if task and task.Cat then
						Category = wx.wxComboBox(TClass, wx.wxID_ANY,task.Cat, wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)
					else
						Category = wx.wxComboBox(TClass, wx.wxID_ANY,list[1], wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)
					end					
					sizer3:Add(Category, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)
					textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, "Sub-Category:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					list = {""}
					for i = 1,#Globals.SubCategories do
						list[i+1] = Globals.SubCategories[i]
					end
					if task and task.SubCat then
						SubCategory = wx.wxComboBox(TClass, wx.wxID_ANY,task.SubCat, wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)
					else
						SubCategory = wx.wxComboBox(TClass, wx.wxID_ANY,list[1], wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)
					end					
					sizer3:Add(SubCategory, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, "Tags:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer1:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				TagsCtrl = CW.MultiSelectCtrl(TClass,filterData.Tags,nil,false,true)
				if task and task.Tags then
					TagsCtrl:AddSelListData(task.Tags)
				end
				sizer1:Add(TagsCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				TClass:SetSizer(sizer1)
			sizer1:SetSizeHints(TClass)
		MainBook:AddPage(TClass, "Classification")				

		-- People Page
		TPeople = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
				-- Resources
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, "People:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				resourceList = wx.wxListCtrl(TPeople, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
				resourceList:InsertColumn(0,"Options")
				-- Populate the resources
				for i = 1,#Globals.Resources do
					CW.InsertItem(resourceList,Globals.Resources[i])
				end
				sizer2:Add(resourceList, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				-- Selection boxes and buttons
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				local sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				AddWhoButton = wx.wxButton(TPeople, wx.wxID_ANY, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(AddWhoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				RemoveWhoButton = wx.wxButton(TPeople, wx.wxID_ANY, "X", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(RemoveWhoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, "Who: (Checked=Active)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				whoList = CW.CheckListCtrl(TPeople,false,"I","A")
				if task and task.Who then
					for i = 1,#task.Who do
						local id = task.Who[i].ID
						if task.Who[i].Status == "Active" then
							whoList:InsertItem(id,true)
						else
							whoList:InsertItem(id)
						end
					end
				end
				sizer4:Add(whoList.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				AddAccButton = wx.wxButton(TPeople, wx.wxID_ANY, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(AddAccButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				RemoveAccButton = wx.wxButton(TPeople, wx.wxID_ANY, "X", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(RemoveAccButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, "Access: (Checked=Read/Write)", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				accList = CW.CheckListCtrl(TPeople,false,"W","R")
				if task and task.Access then
					for i = 1,#task.Access do
						local id = task.Access[i].ID
						if task.Who[i].Status == "Read/Write" then
							accList:InsertItem(id,true)
						else
							accList:InsertItem(id)
						end
					end
				end				
				sizer4:Add(accList.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)

				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				AddAssigButton = wx.wxButton(TPeople, wx.wxID_ANY, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(AddAssigButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				RemoveAssigButton = wx.wxButton(TPeople, wx.wxID_ANY, "X", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
				sizer4:Add(RemoveAssigButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, "Assignee:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
				assigList = wx.wxListCtrl(TPeople, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)
				assigList:InsertColumn(0,"Assignees")
				if task and task.Assignee then
					for i = 1,#task.Assignee do
						CW.InsertItem(assigList,task.Assignee[i].ID)
					end
				end
				sizer4:Add(assigList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				TPeople:SetSizer(sizer1)
			sizer1:SetSizeHints(TPeople)
		MainBook:AddPage(TPeople, "People")				

		-- Schedule Page
		TSch = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)
				dateStartPick = wx.wxDatePickerCtrl(TSch, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
				startDate = dateStartPick:GetValue()
				month = wx.wxDateSpan(0,1,0,0)
				dateFinPick = wx.wxDatePickerCtrl(TSch, wx.wxID_ANY,startDate:Add(month), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
				sizer2:Add(dateStartPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer2:Add(dateFinPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 	wx.wxALIGN_CENTER_VERTICAL), 1)
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				
				taskTree = newGUITreeGantt()(TSch,true)
				sizer1:Add(taskTree.horSplitWin, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)
				dateRangeChange()
				taskTree:layout()
				local localTask = copyTask(task)
				if not localTask then
					localTask = getEmptyTask()
				end
				-- Create the 1st row for the task
			    taskTree:Clear()
			    taskTree:AddNode{Key=localTask.TaskID, Text = localTask.Title, Task = localTask}
			    taskTree.Nodes[localTask.TaskID].ForeColor = GUI.nodeForeColor
			    local prevKey = localTask.TaskID
				-- Get list of mock tasks with incremental schedule
				if task and task.Schedules then
					local taskList = task2IncSchTasks(task)
					-- Now add these tasks
					for i = 1,#taskList do
		            	taskTree:AddNode{Relative=prevKey, Relation="Next Sibling", Key=taskList[i].TaskID, Text=taskList[i].Title, Task = taskList[i]}
		            	taskTree.Nodes[taskList[i].TaskID].ForeColor = GUI.nodeForeColor
		            	prevKey = taskList[i].TaskID
		            end
				end
				-- Enable planning mode for the task
				taskTree:enablePlanningMode({localTask})
				TSch:SetSizer(sizer1)
			sizer1:SetSizeHints(TSch)
		MainBook:AddPage(TSch, "Schedules")				

	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	CancelButton = wx.wxButton(frame, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	sizer1:Add(CancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	DoneButton = wx.wxButton(frame, wx.wxID_ANY, "Done", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
	sizer1:Add(DoneButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	MainSizer:Add(sizer1, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

	frame:SetSizer(MainSizer)

	frame:Connect(wx.wxEVT_CLOSE_WINDOW,
		function (event)
			setfenv(1,package.loaded[modname])		
			event:Skip()
			callBack(nil)
		end
	)

	-- Connect event handlers to the buttons
	RemoveAccButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = accList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				accList.List:DeleteItem(item)			
				item = accList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	RemoveAssigButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = assigList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				assigList:DeleteItem(item)			
				item = assigList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	RemoveWhoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local selItems = {}
			local item = whoList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				whoList.List:DeleteItem(item)
				item = whoList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	AddAccButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				local itemText = resourceList:GetItemText(item)
				accList:InsertItem(itemText)			
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)
	
	AddAssigButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				local itemText = resourceList:GetItemText(item)
				CW.InsertItem(assigList,itemText)		
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	AddWhoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)
			while item ~= -1 do
				local itemText = resourceList:GetItemText(item)
				whoList:InsertItem(itemText)			
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	
			end
		end
	)

	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function (event)
			setfenv(1,package.loaded[modname])		
			frame:Close()
			callBack(nil)
		end
	)
	
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,
		function (event)
			setfenv(1,package.loaded[modname])		
			event:Skip()
			callBack(nil)
		end
	)

	DoneButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			setfenv(1,package.loaded[modname])
			frame:Close()
			callBack(task)
		end		
	)
	
	-- Date Picker Events
	dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,dateRangeChangeEvent)
	dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,dateRangeChangeEvent)
	

    frame:Layout() -- help sizing the windows before being shown
    frame:Show(true)

end	-- function taskFormActivate(parent, callBack)