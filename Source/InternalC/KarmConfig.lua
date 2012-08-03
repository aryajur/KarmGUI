--Spores = {{file = "Test/Tasks.xml",type = "XML"}}
Spores = {
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\AmVed Task Bank.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\Task Bank.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\AmVed Tasks.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\Home Tasks.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\Maxim Tasks.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\ExpressIndianRecipes Tasks.ksf",type = "KSF"}
}

-- GUI Settings
setfenv(1,GUI)
--initFrameH = 800
--initFrameW = 900
MainMenu = {
				-- 1st Menu
				{	
					Text = "&File", Menu = {
											{Text = "E&xit\tCtrl-x", HelpText = "Quit the program", Code = "GUI.frame:Close(true)"}
									}
				},
				-- 2nd Menu
				{	
					Text = "&Tools", Menu = {
											{Text = "&Planning Mode\tCtrl-P", HelpText = "Turn on Planning mode", Code = [[local menuItems = GUI.menuBar:GetMenu(1):GetMenuItems() 
if menuItems:Item(0):GetData():DynamicCast('wxMenuItem'):IsChecked() then 
	-- Enable Planning Mode 
	GUI.taskTree:enablePlanningMode() 
else 
	-- Disable Planning Mode 
	GUI.taskTree:disablePlanningMode() 
end]] , ItemKind = wx.wxITEM_CHECK},
											{Text = "Planning Mode ON for &Tasks\tCtrl-T", HelpText = "Turn on Planning Mode for the selected tasks", Code = [[
	local taskList = GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, GUI.frame)
    else
    	-- Turn on Planning Mode
    	local menuItems = GUI.menuBar:GetMenu(1):GetMenuItems() 
		menuItems:Item(0):GetData():DynamicCast('wxMenuItem'):Check(true) 
		local list = {}
		for i = 1,#taskList do
			if taskList[i].Task and taskList[i].Key:sub(1,#Globals.ROOTKEY) ~= Globals.ROOTKEY then
				list[#list + 1] = taskList[i].Task
			end
		end
		GUI.taskTree:enablePlanningMode(list)
	end
											
											]]},
											{Text = "&Finalize all Planning Schedules\tCtrl-F", HelpText = "Finalize all Planning schedules in the tasks in the UI", Code = [[
	while #GUI.taskTree.taskList > 0 do
		finalizePlanning(GUI.taskTree.taskList[1])
	end
											
											]]},
											{Text = "&Quick Enter Task Under\tCtrl-Q", HelpText = "Quick Entry of task under this task", Code = [[
	-- Get the selected task
	local taskList = GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task under which to create a task.","No Task Selected", wx.wxOK + wx.wxCENTRE, GUI.frame)
        return
	end	
	if #taskList > 1 then
        wx.wxMessageBox("Just select a single task as the parent of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, GUI.frame)
        return
	end		
	-- Get the task Title
	local title = wx.wxGetTextFromUser("Please enter the task Title (Blank to Cancel)", "New Task under", "")
	if title ~= "" then
		local evt = wx.wxCommandEvent(0,GUI.ID_NEW_SUB_TASK)
		NewTask(evt,title)
	end
											]]},								
											{Text = "&Schedule Bubble\tCtrl-B", HelpText = "Bubble up the Schedules", Code = [[local menuItems = GUI.menuBar:GetMenu(1):GetMenuItems() 
if menuItems:Item(4):GetData():DynamicCast('wxMenuItem'):IsChecked() then 
	-- Enable Bubbling Mode 
	GUI.taskTree.Bubble = true
	fillTaskTree()
else 
	-- Disable Bubbling Mode 
	GUI.taskTree.Bubble = false
	fillTaskTree()
end]] , ItemKind = wx.wxITEM_CHECK},										
											{Text = "&Show Work Done\tCtrl-W", HelpText = "Show Actual Work Done", Code = [[
	GUI.taskTree.ShowActual = true
	fillTaskTree()
											]]},										
											{Text = "&Show Normal Schedule\tCtrl-N", HelpText = "Show Normal Schedule", Code = [[
	GUI.taskTree.ShowActual = nil
	fillTaskTree()
											]]}									
									}
				},
				-- 3rd Menu
				{	
					Text = "&Help", Menu = {
											{Text = "&About\tCtrl-A", HelpText = "About Karm", Code = "wx.wxMessageBox('Karm is the Task and Project management application for everybody.\\n Version: '..Globals.KARM_VERSION, 'About Karm',wx.wxOK + wx.wxICON_INFORMATION,GUI.frame)"}
									}
				}
}
setfenv(1,_G)
-- print(Spores)

Globals.Categories = {
	"Design",
	"Definition",
	"Maintainence"
}

Globals.SubCategories = {
	"Phase 1",
	"Development",
	"Phase 3"
}

Globals.Resources = {
	"milind.gupta",
	"deepshikha.dandora",
	"arnav.gupta"
}

Globals.User = "milind.gupta"
Globals.UserIDPattern = "%'([%w%.%_%,% ]+)%'"

Globals.safeenv = {}
setmetatable(Globals.safeenv,{__index = _G})
--[[
function AutoFillTask(task)
	task.Who[#task.Who + 1] = {ID = "deepshikha.dandora", Status = "Inactive"}
	task.Who.count = task.Who.count + 1
end
]]

function checkTask(task)
	if task.SubCat and not task.Cat then
		return nil, "Category cannot be blank if Sub-Category is set."
	end
	-- If there is a Due date and current date is larger than that then set Status to Behind
	-- If there is a schedule and status is Not Started then set Status to On Track
	return true
end

-- Function to auto fill a task
--[[
function AutoFillTask(task)

end
]]

-- Initial Filter

--Filter = {
--	Tasks = {
--		{TaskID = "TechChores",	Children = true, Title = "Technical Work"}
--	},
--	Who = "'milind.gupta,A' and not('aryajur,A')"
--}
do
	local safeenv = {}
	setmetatable(safeenv, {__index = Globals.safeenv})
	local f,message = loadfile("C:\\Users\\milind.gupta\\Documents\\Tasks\\Filters\\All_Tasks.kff")
	if f then
		setfenv(f,safeenv)
		f()
		if safeenv.filter and type(safeenv.filter) == "table" then
			Filter = safeenv.filter
		end
	end
end
