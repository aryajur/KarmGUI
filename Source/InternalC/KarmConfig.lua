Spores = {"Test/Tasks.xml"}
-- Initial Filter
--[[Filter = {
	Tasks = {
		{TaskID = "TechChores",	Children = true, Title = "Technical Work"}
	},
	Who = "'milind.gupta,A' and not('aryajur,A')"
}]]


-- GUI Settings
setfenv(1,GUI)
initFrameH = 800
initFrameW = 900
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
