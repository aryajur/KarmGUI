--Spores = {{file = "Test/Tasks.xml",type = "XML"}}
Karm.Spores = {
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
											{Text = "Change &ID\tCtrl-I", HelpText = "Change the User ID", Code = [[
local user = wx.wxGetTextFromUser("Enter the user ID (Blank to cancel)", "User ID", "")
if user ~= "" then
	Karm.Globals.User = user
	Karm.GUI.frame:SetTitle("Karm ("..Karm.Globals.User..")")
end											
											]]},
											{Text = "E&xit\tCtrl-x", HelpText = "Quit the program", Code = "Karm.GUI.frame:Close(true)"}
									}
				},
				-- 2nd Menu
				{	
					Text = "&Tools", Menu = {
											{Text = "&Planning Mode\tCtrl-P", HelpText = "Toggle Planning mode", Code = [[
	local menuItem = Karm.GUI.menuBar:FindItem(myID)
	if menuItem:IsChecked() then 
		-- Enable Planning Mode 
		Karm.GUI.taskTree:enablePlanningMode() 
	else 
		-- Disable Planning Mode 
		Karm.GUI.taskTree:disablePlanningMode() 
	end											
											]], ItemKind = wx.wxITEM_CHECK},
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
if Karm.GUI.taskTree.taskList then
	while #Karm.GUI.taskTree.taskList > 0 do
		Karm.finalizePlanning(Karm.GUI.taskTree.taskList[1].Task, Karm.GUI.taskTree.Planning)
	end
end
											]]},
											{Text = "&Quick Enter Task Under\tCtrl-Q", HelpText = "Quick Entry of task under this task", Code = [[
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
					Text = "&Filters", Menu = {
											{Text = "&Show Not Done Tasks under also\tCtrl-1", HelpText = "All not done tasks under this task will also show", Code = [[
-- Get selected task first
local taskList = Karm.GUI.taskTree.Selected
if #taskList == 0 then
    wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    return
end			
if #taskList > 1 then
    wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    return
end	
local filter = Karm.Filter
if filter.Map then
	-- This is already a filter combination
	filter.Map.count = filter.Map.count + 1
	filter.Map["F"..filter.Map.count] = {Name = "F"..filter.Map.count..":"..taskList[1].Task.Title.." and not done Children", Filter = {Status="Behind,Not Started,On Track",Tasks={[1]={TaskID=taskList[1].Task.TaskID,Title=taskList[1].Task.Title,Children="true"}}}}
	filter.Bool = filter.Bool.." or '"..filter.Map["F"..filter.Map.count].Name.."'"
else
	-- Make this a filter combination
	Karm.Filter = {
				Map = {count = 2,
				F1 = {Name = "F1:Previous Filter", Filter = Karm.Filter},
				F2 = {Name = "F2:"..taskList[1].Task.Title.." and not done Children", Filter = {Status="Behind,Not Started,On Track",Tasks={[1]={TaskID=taskList[1].Task.TaskID,Title=taskList[1].Task.Title,Children="true"}}}} 
				},
				Bool = "'F1:Previous Filter' or 'F2:"..taskList[1].Task.Title.." and not done Children'"
	}
end
Karm.GUI.fillTaskTree()
											]]},
											{Text = "&Scheduled but not done\tCtrl-4", HelpText = "Tasks scheduled before today and not marked done", Code = [[
local filter = Karm.LoadFilter("C:\\Users\\milind.gupta\\Documents\\Tasks\\Filters\\Scheduled_But_Not_Done.kff")
Karm.Filter = filter
Karm.GUI.fillTaskTree()
											]]},
											{Text = "&Coming Week not Done\tCtrl-5", HelpText = "Tasks scheduled in the coming week", Code = [[
local filter = Karm.LoadFilter("C:\\Users\\milind.gupta\\Documents\\Tasks\\Filters\\Coming_Week_Not_Done.kff")
Karm.Filter = filter
Karm.GUI.fillTaskTree()
											]]},
											{Text = "&Today Not Done\tCtrl-6", HelpText = "Tasks scheduled for today", Code = [[
local filter = Karm.LoadFilter("C:\\Users\\milind.gupta\\Documents\\Tasks\\Filters\\Today_Not_Done.kff")
Karm.Filter = filter
Karm.GUI.fillTaskTree()
											]]},
											{Text = "All &Not Done, Non Obsolete\tCtrl-7", HelpText = "Tasks scheduled for today", Code = [[
local filter = Karm.LoadFilter("C:\\Users\\milind.gupta\\Documents\\Tasks\\Filters\\All_Not_Done_Non_Obsolete.kff")
Karm.Filter = filter
Karm.GUI.fillTaskTree()
											]]},
											{Text = "&All Tasks\tCtrl-8", HelpText = "Show all loaded Tasks", Code = [[
local filter = Karm.LoadFilter("C:\\Users\\milind.gupta\\Documents\\Tasks\\Filters\\All_Tasks.kff")
Karm.Filter = filter
Karm.GUI.fillTaskTree()
											]]}
									}
				},
				-- 4th Menu
				{	
					Text = "&Help", Menu = {
												{Text = "&About\tCtrl-A", HelpText = "About Karm", Code = [[
		wx.wxMessageBox('Karm is the Task and Project management application for everybody.\n    Version: '..Karm.Globals.KARM_VERSION.."\nFor Help:\n    wiki.karm.amved.com\n    forum.karm.amved.com\n    karm@amved.com", 'About Karm',wx.wxOK + wx.wxICON_INFORMATION,Karm.GUI.frame)]]
												}
									}
				}
}

setfenv(1,_G)
-- print(Spores)

function myDebugFunc()

--- PASTE SCRIPT TO DEBUG HERE

--- END CUSTOM SCRIPT

end

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
