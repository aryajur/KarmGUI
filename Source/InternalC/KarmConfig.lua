--Spores = {{file = "Test/Tasks.xml",type = "XML"}}
Karm.Spores = {
		{file = "../../../../../../../Tasks/Micrel.ksf",type = "KSF"},
		{file = "../../../../../../../Tasks/AmVed Tasks.ksf",type = "KSF"},
		{file = "../../../../../../../Tasks/Home Tasks.ksf",type = "KSF"},
		{file = "../../../../../../../Tasks/Neukleus.ksf",type = "KSF"},
		--{file = "../../../../../../../Tasks/Arnav.ksf",type = "KSF"},
		--{file = "../../../../../../../Tasks/ExpressIndianRecipes Tasks.ksf",type = "KSF"}
}

-- Karm.GUI Settings
setfenv(1,Karm.GUI)
-- initFrame variables set the initial window size otherwise default size generated based on screen size
--initFrameH = 800
--initFrameW = 900
-- Add command to the 2nd menu:
MainMenu[2].Menu[#MainMenu[2].Menu + 1] = {Text = "&Show Hierarchy\tCtrl-H", HelpText = "Show selected task hierarchy", Code = [[
local taskList = Karm.GUI.taskTree.Selected
if #taskList == 0 then
	-- No task selected - nothing to do
	wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
else
	local currTask = taskList[1].Task
	local hier = "--> "..currTask.Title
	while currTask.Parent do
		hier = "--> "..currTask.Parent.Title.."\n"..hier
		currTask = currTask.Parent
	end
	-- Display the hierarchy
	wx.wxMessageBox(hier)
end
											]]}
											

MainMenu[2].Menu[#MainMenu[2].Menu + 1] = {Text = "&Add Estimate\tCtrl-E", HelpText = "Add Estimated time to the task", Code = [[
local taskList = Karm.GUI.taskTree.Selected
if #taskList == 0 then
	-- No task selected - nothing to do
	wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
else
  local estimate
  if Karm.Globals.EstimateUnit == "H" then
    estimate = wx.wxGetTextFromUser("Please enter the estimated hours for the task (Blank to Cancel)", "Estimated Hours to complete", "")
	else
    estimate = wx.wxGetTextFromUser("Please enter the estimated days for the task (Blank to Cancel)", "Estimated Days to complete", "")
  end
  if estimate ~="" and tonumber(estimate)~=0 then
    local currTask = taskList[1].Task
    currTask.Estimate = tostring(tonumber(estimate))
    -- Refresh the task
    Karm.GUI.taskTree:RefreshNode(currTask)
  end
end
											]]}

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
	local f,message = loadfile("../../../../../../../Tasks/Filters/All_Tasks.kff")
	if f then
		setfenv(f,safeenv)
		f()
		if safeenv.filter and type(safeenv.filter) == "table" then
			Karm.Filter = safeenv.filter
		end
	end
end
