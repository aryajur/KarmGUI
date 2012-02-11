-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application Criteria Entry form UI creation and handling file
-- Author:      Milind Gupta
-- Created:     2/09/2012
-----------------------------------------------------------------------------

function filterFormActivate(parent)

	GUI.filterForm = {["__index"]=_G}
	setmetatable(GUI.filterForm,GUI.filterForm)
	setfenv(1,GUI.filterForm)


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
					TandCSizer:Add(TaskSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

					CategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, "Select Categories", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					TandCSizer:Add(CategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					
					-- Category List boxes and buttons
					CatCtrl = GUI.MultiSelectCtrl.new(TandC,{"item 1","item 2","item 3"})
					TandCSizer:Add(CatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					
					SubCategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, "Select Sub-Categories", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
					TandCSizer:Add(SubCategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					-- Sub Category Listboxes and Buttons
					SubCatCtrl = GUI.MultiSelectCtrl.new(TandC,{"item 1","item 2","item 3"},{"item 1","item 2","item 3"})
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
				PriCtrl = GUI.MultiSelectCtrl.new(PSandTag,Globals.PriorityList)
				PSandTagSizer:Add(PriCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				StatusLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, "Select Status", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				PSandTagSizer:Add(StatusLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Status List boxes and buttons
				StatCtrl = GUI.MultiSelectCtrl.new(PSandTag,Globals.StatusList)
				PSandTagSizer:Add(StatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)

				TagsLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, "Select Tags", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
				PSandTagSizer:Add(TagsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
				
				-- Tag List box, buttons and tree
				local TagSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
					TagList = wx.wxListBox(PSandTag, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(0.1*GUI.initFrameW, 0.1*GUI.initFrameH),{"hello","good","1 hour", "2 hour"},wx.wxLB_EXTENDED)
					TagSizer:Add(TagList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					local TagButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)
						ANDTagButton = wx.wxButton(PSandTag, wx.wxID_ANY, "AND", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagButtonSizer:Add(ANDTagButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						ORTagButton = wx.wxButton(PSandTag, wx.wxID_ANY, "OR", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagButtonSizer:Add(ORTagButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						NANDTagButton = wx.wxButton(PSandTag, wx.wxID_ANY, "NOT() AND", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagButtonSizer:Add(NANDTagButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						NORTagButton = wx.wxButton(PSandTag, wx.wxID_ANY, "NOT () OR", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagButtonSizer:Add(NORTagButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						ANDNTagButton = wx.wxButton(PSandTag, wx.wxID_ANY, "AND NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagButtonSizer:Add(ANDNTagButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						ORNTagButton = wx.wxButton(PSandTag, wx.wxID_ANY, "OR NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagButtonSizer:Add(ORNTagButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						NANDNTagButton = wx.wxButton(PSandTag, wx.wxID_ANY, "NOT() AND NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagButtonSizer:Add(NANDNTagButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
						NORNTagButton = wx.wxButton(PSandTag, wx.wxID_ANY, "NOT() OR NOT", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
						TagButtonSizer:Add(NORNTagButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					TagSizer:Add(TagButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
					SelTagTree = wx.wxTreeCtrl(PSandTag, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(0.1*GUI.initFrameW, 0.1*GUI.initFrameH),wx.wxTR_EXTENDED)
					TagSizer:Add(SelTagTree, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
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

--	Connect(wxID_ANY,wxEVT_CLOSE_WINDOW,(wxObjectEventFunction)&CriteriaFrame::OnClose);

    GUI.filterForm.frame:Layout() -- help sizing the windows before being shown

    GUI.filterForm.frame:Show(true)
	setfenv(1,_G)

end

-- Two List boxes and 2 buttons in between class
GUI.MultiSelectCtrl = {

__index = GUI.MultiSelectCtrl,

InsertItem = function(ListBox,Item)

end,

AddPress = function(event)
	print("Add Pressed for "..tostring(GUI.MultiSelectCtrl[event:GetId()]))
end,

RemovePress = function(event)
	print("Remove Pressed for "..tostring(GUI.MultiSelectCtrl[event:GetId()]))
end,

new = function(parent, LItems, RItems)
	if not parent then
		return nil
	end
	LItems = LItems or {}
	RItems = RItems or {} 
	local o = {}	-- new object
	setmetatable(o,GUI.MultiSelectCtrl)
	-- Create the GUI elements here
	o.Sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
		o.List = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,bit.bor(wx.wxLC_REPORT,wx.wxLC_NO_HEADER))
		-- Add Items
		local col = wx.wxListItem()
		col:SetId(0)
		o.List:InsertColumn(0,col)
		for i=1,#LItems do
			local item = wx.wxListItem()
			item:SetId(i)
			item:SetText(LItems[i])
			o.List:InsertItem(item)
		end
		o.Sizer:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		o.ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local ID = NewID()
			o.AddButton = wx.wxButton(parent, ID, ">", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			o.ButtonSizer:Add(o.AddButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			GUI.MultiSelectCtrl[ID] = o 
			ID = NewID()
			o.RemoveButton = wx.wxButton(parent, ID, "<", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			o.ButtonSizer:Add(o.RemoveButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			GUI.MultiSelectCtrl[ID] = o
		o.Sizer:Add(o.ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		o.SelList = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,bit.bor(wx.wxLC_REPORT,wx.wxLC_NO_HEADER))
		-- Add Items
		local col = wx.wxListItem()
		col:SetId(0)
		o.SelList:InsertColumn(0,col)
		for i=1,#RItems do
			local item = wx.wxListItem()
			item:SetId(i)
			item:SetText(LItems[i])
			o.SelList:InsertItem(item)
		end
		o.Sizer:Add(o.SelList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	-- Connect the buttons to the event handlers
	o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,GUI.MultiSelectCtrl.AddPress)
	o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,GUI.MultiSelectCtrl.RemovePress)
	return o
end

}
