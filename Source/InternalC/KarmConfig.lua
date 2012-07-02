--Spores = {{file = "Test/Tasks.xml",type = "XML"}}
Spores = {
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\AmVed Task Bank.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\Task Bank.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\AmVed Tasks.ksf",type = "KSF"},
		{file = "C:\\Users\\milind.gupta\\Documents\\Tasks\\Home Tasks.ksf",type = "KSF"}
}

-- Initial Filter

--Filter = {
--	Tasks = {
--		{TaskID = "TechChores",	Children = true, Title = "Technical Work"}
--	},
--	Who = "'milind.gupta,A' and not('aryajur,A')"
--}


-- GUI Settings
setfenv(1,GUI)
initFrameH = 800
initFrameW = 900
MainMenu = {
				-- 1st Menu
				{	
					Text = "&File", Menu = {
											{Text = "&Open\tCtrl-O", HelpText = "Open a Spore", Code = "openKarmSpore()"},
											{Text = "E&xit\tCtrl-x", HelpText = "Quit the program", Code = "GUI.frame:Close()"}
									}
				},
				-- 2nd Menu
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
