if Karm.GUI.taskTree.taskList then
	while #Karm.GUI.taskTree.taskList > 0 do
		Karm.finalizePlanning(Karm.GUI.taskTree.taskList[1])
	end
end
