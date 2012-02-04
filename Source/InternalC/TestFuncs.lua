

-- To fill the GUI with Dummy data in the treeList and ganttList
function fillDummyData()

	GUI.treeGrid:SetCellValue(0,0,"Test Item 0")
	GUI.treeGrid:SetCellBackgroundColour(0,0,wx.wxColour(255,255,255))
    for i = 1,100 do
    	GUI.treeGrid:InsertRows(i)
		GUI.treeGrid:SetCellValue(i,0,"Test Item " .. i)
		GUI.treeGrid:SetCellBackgroundColour(i,0,wx.wxColour(255,255,255))
	end
	-- GUI.treeGrid:SetScrollbars(3,3,treeGrid:GetSize():GetWidth(),treeGrid:GetSize():GetHeight())
	
	-- Fill the gantt chart list
	date = 17
	for i = 0,100 do	-- row count
		if i > 0 then 
			-- insert a row
			GUI.ganttGrid:InsertRows(i)
		end
		for j = 0,29 do
			if i == 0 then
				if j > 0 then
					-- insert a column
					GUI.ganttGrid:InsertCols(j)
				end
				-- set the column labels
				GUI.ganttGrid:SetColLabelValue(j,tostring(date+j))
				GUI.ganttGrid:SetColSize(j,25)
			end
			if (i+j)%2 == 0 then
				GUI.ganttGrid:SetCellBackgroundColour(i,j,wx.wxColour(128,34,170))
			end
		end
	end

	-- GUI.ganttGrid:SetScrollbars(3,3,ganttGrid:GetSize():GetWidth(),ganttGrid:GetSize():GetHeight())
end

-- function to populate the task tree with all teh tasks in a list od Spores i.e. SporeData can be directly passed to this function
function updateTree(treeData)
	-- treeData should be the array of spore dataStruct returned by XML2DATA
	GUI.treeGrid:DeleteRows(0,GUI.treeGrid:GetNumberRows())
	GUI.ganttGrid:DeleteRows(0,GUI.ganttGrid:GetNumberRows())
	local taskTree = {}	-- Table to store the GUI state which will replace the GUI.taskTree table
	local rowPtr = 0
	local hierLevel = 0
	for i,spore in pairs(treeData) do
		if i ~=0 then
			local counts = {[spore] = 1} -- to count the children in the spore/task
			while(spore[counts[spore]] or spore.parent) do
				if not spore[counts[spore]] then
					-- go up a level
					spore = spore.parent
					hierLevel = hierLevel - 1
				else
					if spore[counts[spore]].Title then
						GUI.treeGrid:InsertRows(rowPtr)
						GUI.treeGrid:SetCellValue(rowPtr,0,string.rep(" ",hierLevel*4)..spore[counts[spore]].Title)
						rowPtr = rowPtr + 1
					end
					if spore[counts[spore]].SubTasks then
						spore = spore[counts[spore]].SubTasks
						hierLevel = hierLevel + 1
						counts[spore] = 0
					end
				end
				counts[spore] = counts[spore] + 1
			end		-- while(treeData[i]) ends
		end		-- if i ~=0 then ends
	end		-- Looping through all the spores	
	GUI.treeGrid:SetColMinimalWidth(0,GUI.horSplitWin:GetSashPosition())
	GUI.treeGrid:AutoSizeColumn(0,false)
end		-- function updateTree(treeData) ends

-- function to populate the task tree with all the tasks in GUI.taskTree
function refreshTree()
	-- Erase the previous data
	GUI.treeGrid:DeleteRows(0,GUI.treeGrid:GetNumberRows())
	GUI.ganttGrid:DeleteRows(0,GUI.ganttGrid:GetNumberRows())
	local rowPtr = 0
	local hierLevel = 0
	for i,v in GUI.taskTree.tpairs(GUI.taskTree.Nodes) do
		GUI.dispTask(rowPtr+1,true,v,0)
		GUI.dispGantt(rowPtr+1,true,v)
		rowPtr = rowPtr + 1
	end		-- Looping through all the nodes ends	
	GUI.treeGrid:SetColMinimalWidth(0,GUI.horSplitWin:GetSashPosition())
	GUI.treeGrid:AutoSizeColumn(0,false)
end		-- function updateTree(treeData) ends

