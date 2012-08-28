if not Karm.GUI.taskTree.Bubble then
	-- Enable Bubbling Mode 
	Karm.GUI.taskTree.Bubble = true
	Karm.GUI.fillTaskTree()
else 
	-- Disable Bubbling Mode 
	Karm.GUI.taskTree.Bubble = false
	Karm.GUI.fillTaskTree()
end