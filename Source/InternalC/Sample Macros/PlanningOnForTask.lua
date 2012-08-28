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
