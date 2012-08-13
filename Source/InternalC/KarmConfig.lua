--Spores = {{file = "Test/Tasks.xml",type = "XML"}}
Spores = {
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\AmVed Task Bank.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\Task Bank.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\AmVed Tasks.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\Home Tasks.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\Maxim Tasks.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\ExpressIndianRecipes Tasks.ksf",type = "KSF"}
}

-- Karm.GUI Settings
setfenv(1,Karm.GUI)
--initFrameH = 800
--initFrameW = 900
MainMenu = {
				-- 1st Menu
				{	
					Text = "&File", Menu = {
											{Text = "E&xit\tCtrl-x", HelpText = "Quit the program", Code = "Karm.GUI.frame:Close(true)"}
									}
				},
				-- 2nd Menu
				{	
					Text = "&Tools", Menu = {
											{Text = "&Planning Mode\tCtrl-P", HelpText = "Turn on Planning mode", Code = [[local menuItems = Karm.GUI.menuBar:GetMenu(1):GetMenuItems() 
if menuItems:Item(0):GetData():DynamicCast('wxMenuItem'):IsChecked() then 
	-- Enable Planning Mode 
	Karm.GUI.taskTree:enablePlanningMode() 
else 
	-- Disable Planning Mode 
	Karm.GUI.taskTree:disablePlanningMode() 
end]] , ItemKind = wx.wxITEM_CHECK},
											{Text = "Planning Mode ON for &Tasks\tCtrl-T", HelpText = "Turn on Planning Mode for the selected tasks", Code = [[
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    else
    	-- Turn on Planning Mode
    	local menuItems = Karm.GUI.menuBar:GetMenu(1):GetMenuItems() 
		menuItems:Item(0):GetData():DynamicCast('wxMenuItem'):Check(true) 
		local list = {}
		for i = 1,#taskList do
			-- Select nodes that only have actual tasks and which are not spores 
			if taskList[i].Task and not Karm.TaskObject.IsSpore(taskList[i].Task) then
				list[#list + 1] = taskList[i].Task
				-- Mark the unsaved spores list so saving message is displayed
				Karm.Globals.unsavedSpores[taskList[i].Task.SporeFile] = Karm.SporeData[taskList[i].Task.SporeFile].Title
			end
		end
		Karm.GUI.taskTree:enablePlanningMode(list)
	end
											
											]]},
											{Text = "&Finalize all Planning Schedules\tCtrl-F", HelpText = "Finalize all Planning schedules in the tasks in the UI", Code = [[
	while #Karm.GUI.taskTree.taskList > 0 do
		Karm.finalizePlanning(Karm.GUI.taskTree.taskList[1])
	end
											
											]]},
											{Text = "&Quick Enter Task Under\tCtrl-Q", HelpText = "Quick Entry of task under this task", Code = [[
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task under which to create a task.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end	
	if #taskList > 1 then
        wx.wxMessageBox("Just select a single task as the parent of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end		
	-- Get the task Title
	local title = wx.wxGetTextFromUser("Please enter the task Title (Blank to Cancel)", "New Task under", "")
	if title ~= "" then
		local evt = wx.wxCommandEvent(0,Karm.GUI.ID_NEW_SUB_TASK)
		Karm.NewTask(evt,title)
	end
											]]},								
											{Text = "&Schedule Bubble\tCtrl-B", HelpText = "Bubble up the Schedules", Code = [[local menuItems = Karm.GUI.menuBar:GetMenu(1):GetMenuItems() 
if menuItems:Item(4):GetData():DynamicCast('wxMenuItem'):IsChecked() then 
	-- Enable Bubbling Mode 
	Karm.GUI.taskTree.Bubble = true
	Karm.GUI.fillTaskTree()
else 
	-- Disable Bubbling Mode 
	Karm.GUI.taskTree.Bubble = false
	Karm.GUI.fillTaskTree()
end]] , ItemKind = wx.wxITEM_CHECK},										
											{Text = "&Show Work Done\tCtrl-W", HelpText = "Show Actual Work Done", Code = [[
	Karm.GUI.taskTree.ShowActual = true
	Karm.GUI.fillTaskTree()
											]]},										
											{Text = "&Show Normal Schedule\tCtrl-N", HelpText = "Show Normal Schedule", Code = [[
	Karm.GUI.taskTree.ShowActual = nil
	Karm.GUI.fillTaskTree()
											]]}									
									}
				},
				-- 3rd Menu
				{	
					Text = "&Help", Menu = {
											{Text = "&About\tCtrl-A", HelpText = "About Karm", Code = "wx.wxMessageBox('Karm is the Task and Project management application for everybody.\\n Version: '..Karm.Globals.KARM_VERSION, 'About Karm',wx.wxOK + wx.wxICON_INFORMATION,Karm.GUI.frame)"}
									}
				}
}
setfenv(1,_G)
-- print(Spores)

Karm.Globals.Categories = {
	"Design",
	"Definition",
	"Maintainence"
}

Karm.Globals.SubCategories = {
	"Phase 1",
	"Development",
	"Phase 3"
}

Karm.Globals.Resources = {
	"milind.gupta",
	"deepshikha.dandora",
	"arnav.gupta"
}

Karm.Globals.User = "milind.gupta"
Karm.Globals.UserIDPattern = "%'([%w%.%_%,% ]+)%'"

Karm.Globals.safeenv = {}
setmetatable(Karm.Globals.safeenv,{__index = _G})
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
	if task.Schedules and task.Status == "Not Started" then
		task.Status = "On Track"
	end
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
	setmetatable(safeenv, {__index = Karm.Globals.safeenv})
	local f,message = loadfile("C:\\Users\\milind.gupta\\Documents\\Tasks\\Filters\\All_Tasks.kff")
	if f then
		setfenv(f,safeenv)
		f()
		if safeenv.filter and type(safeenv.filter) == "table" then
			Karm.Filter = safeenv.filter
		end
	end
end
