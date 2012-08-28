-- Get the task Title
local title = wx.wxGetTextFromUser("Please enter the task Title (Blank to Cancel)", "New Task under", "")
if title ~= "" then
	local evt = wx.wxCommandEvent(0,Karm.GUI.ID_NEW_SUB_TASK)
	Karm.NewTask(evt,title)
end
