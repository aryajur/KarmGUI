Spores = {"Test/Tasks.xml"}
-- Initial Filter
Filter = {
	Tasks = {
		{TaskID = "TechChores",	Children = true, Title = "Technical Work"}
	},
	Who = "'milind.gupta,A' and not('aryajur,A')"
}

-- GUI Settings
setfenv(1,GUI)
initFrameH = 400
initFrameW = 450
setfenv(1,_G)
-- print(Spores)
