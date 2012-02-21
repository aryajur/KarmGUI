-- Table to store all the Spores data 
SporeData = {}

function getTaskSummary(task)
	if task then
		local taskSummary
		taskSummary = "ID: "..task.TaskID.."\nSTART DATE: "..task.Start
		if task.Fin then
			taskSummary = taskSummary.."\nFINISH DATE: "..task.Fin
		end
		taskSummary = taskSummary.."\nSTATUS: "..task.Status
		-- Responsible People
		taskSummary = taskSummary.."\nPEOPLE: "
		local ACT = ""
		local INACT = ""
		for i=1,task.Who.count do
			if string.upper(task.Who[i].Status) == "ACTIVE" then
				ACT = ACT..","..task.Who[i].ID
			else
				INACT = INACT..","..task.Who[i].ID
			end
		end
		if #ACT > 0 then
			taskSummary = taskSummary.."\n   ACTIVE: "..string.sub(ACT,2,-1)
		end
		if #INACT > 0 then
			taskSummary = taskSummary.."\n   INACTIVE: "..string.sub(INACT,2,-1)
		end
		taskSummary = taskSummary.."\nLOCKED: "..task.Locked.Status
		if string.upper(task.Locked.Status) == "YES" and task.Locked.Access then
			local RA = ""
			local RWA = ""
			for i = 1,task.Locked.Access.count do
				if string.upper(task.Locked.Access[i].Status) == "READ ONLY" then
					RA = RA..","..task.Locked.Access[i].ID
				else
					RWA = RWA..","..task.Locked.Access[i].ID
				end
			end
			if #RA > 0 then
				taskSummary = taskSummary.."\n   READ ACCESS PEOPLE: "..string.sub(RA,2,-1)
			end
			if #RWA > 0 then
				taskSummary = taskSummary.."\n   READ/WRITE ACCESS PEOPLE: "..string.sub(RWA,2,-1)
			end
		end
		return taskSummary
	else
		return "No Task Selected"
	end
end

function getLatestScheduleDates(task)
	local typeSchedule, index
	local dateList = {}
	if task.Schedules then
		-- Find the latest schedule in the task here
		if string.upper(task.Status) == "DONE" and task.Schedules.Actual then
			typeSchedule = "Actual"
			index = 1
		elseif task.Schedules.Revs then
			-- Actual is not the latest one but Revision is 
			typeSchedule = "Revs"
			index = task.Schedules.Revs.count
		elseif task.Schedules.Commit then
			-- Actual and Revisions don't exist but Commit does
			typeSchedule = "Commit"
			index = 1
		else
			-- The latest is Estimate
			typeSchedule = "Estimate"
			index = task.Schedules.Estimate.count
		end
		-- Now we have the latest schedule type in typeSchedule and the index of it in index
		for i = 1,#task.Schedules[typeSchedule][index].Period do
			dateList[#dateList + 1] = task.Schedules[typeSchedule][index].Period[i].Date
		end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends
		dateList.typeSchedule = typeSchedule
		dateList.index = index
		return dateList
	else
		return nil
	end
end
--****f* Karm/ToXMLDate
-- FUNCTION
-- Function to convert display format date to XML format date YYYY-MM-DD
-- display date format is MM/DD/YYYY
--
-- INPUT
-- o displayDate -- String variable containing the date string as MM/DD/YYYY
--
-- RETURNS
-- The date as a string compliant to XML date format YYYY-MM-DD
--
-- SOURCE
function toXMLDate(displayDate)
--@@END@@

    local exYear, exMonth, exDate
    local count = 1
    for num in string.gmatch(displayDate,"%d+") do
    	if count == 1 then
    		-- this is month
    		exMonth = num
	    	if #exMonth == 1 then
        		exMonth = "0" .. exMonth
        	end
        elseif count==2 then
        	-- this is the date
        	exDate = num
        	if #exDate == 1 then
        		exDate = "0" .. exDate
        	end
        elseif count== 3 then
        	-- this is the year
        	exYear = num
        	if #exYear == 1 then
        		exYear = "000" .. exYear
        	elseif #exYear == 2 then
        		exYear = "00" .. exYear
        	elseif #exYear == 3 then
        		exYear = "0" .. exYear
        	end
        end
        count = count + 1
	end    
    return exYear .. "-" .. exMonth .. "-" .. exDate
end

-- Function to convert XML data from a single spore to internal data structure
function XML2Data(SporeXML, SporeFile)
	-- tasks counts the number of tasks at the current level
	-- index 0 contains the name of this level to make it compatible with LuaXml
	local dataStruct = {tasks = 0, [0] = "Task_Spore"}	-- to create the data structure
	if SporeXML[0]~="Task_Spore" then
		return nil
	end
	local currNode = SporeXML
	local hierInfo = {}
	hierInfo[currNode] = {count = 1}
	while(currNode[hierInfo[currNode].count] or hierInfo[currNode].parent) do
		if not(currNode[hierInfo[currNode].count]) then
			currNode = hierInfo[currNode].parent
			dataStruct = dataStruct.parent
		else
			if currNode[hierInfo[currNode].count][0] == "Task" then
				local task = currNode[hierInfo[currNode].count]
				hierInfo[currNode].count = hierInfo[currNode].count + 1
				local necessary = 0
				dataStruct.tasks = dataStruct.tasks + 1
				dataStruct[dataStruct.tasks] = {[0] = "Task"}
				dataStruct[dataStruct.tasks].SporeFile = SporeFile
				-- Extract all task information here
				local count = 1
				while(task[count]) do
					if task[count][0] == "Title" then
						dataStruct[dataStruct.tasks].Title = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "TaskID" then
						dataStruct[dataStruct.tasks].TaskID = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Start" then
						dataStruct[dataStruct.tasks].Start = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Fin" then
						dataStruct[dataStruct.tasks].Fin = task[count][1]
					elseif task[count][0] == "Who" then
						local WhoTable = {[0]="Who", count = #task[count]}
						-- Loop through all the items in the Who element
						for i = 1,#task[count] do
							WhoTable[i] = {ID = task[count][i][1][1], Status = task[count][i][2][1]}
						end
						necessary = necessary + 1
						dataStruct[dataStruct.tasks].Who = WhoTable
					elseif task[count][0] == "Locked" then
						local locked = {[0]="Locked", Status = task[count][1][1]}
						if string.upper(locked.Status) == "YES" then
							if type(task[count][2]) == "table" and task[count][2][0] == "Access" then
								local AccessTable = {[0]="Access", count = #task[count][2]}
								-- Loop through all the items in the Locked element Access List
								for i = 1,#task[count][2] do
									AccessTable[i] = {ID = task[count][2][i][1][1], Status = task[count][2][i][2][1]}
								end
								locked.Access = AccessTable
							end
						end
						necessary = necessary + 1
						dataStruct[dataStruct.tasks].Locked = locked
					elseif task[count][0] == "Status" then
						dataStruct[dataStruct.tasks].Status = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Priority" then
						dataStruct[dataStruct.tasks].Priority = task[count][1]
					elseif task[count][0] == "Due" then
						dataStruct[dataStruct.tasks].Due = task[count][1]
					elseif task[count][0] == "Comments" then
						dataStruct[dataStruct.tasks].Comments = task[count][1]
					elseif task[count][0] == "Category" then
						dataStruct[dataStruct.tasks].Cat = task[count][1]
					elseif task[count][0] == "Sub-Category" then
						dataStruct[dataStruct.tasks].SubCat = task[count][1]
					elseif task[count][0] == "Tags" then
						local tagTable = {[0]="Tags", count = #task[count]}
						-- Loop through all the items in the Tags element
						for i = 1,#task[count] do
							tagTable[i] = task[count][i][0]
						end
						dataStruct[dataStruct.tasks].Tags = tagTable
					elseif task[count][0] == "Schedules" then
						local schedule = {[0]="Schedules"}
						for i = 1,#task[count] do
							if task[count][i][0] == "Estimate" then
								local estimate = {[0]="Estimate", count = #task[count][i]}
								-- Loop through all the estimates
								for j = 1,#task[count][i] do
									estimate[j] = {[0]="Estimate"}
									-- Loop through the children of Estimates element
									for n = 1,#task[count][i][j] do
										if task[count][i][j][n][0] == "Hours" then
											estimate[j].Hours = task[count][i][j][n][1]
										elseif task[count][i][j][n][0] == "Comment" then
											estimate[j].Comment = task[count][i][j][n][1]
										elseif task[count][i][j][0] == "Updated" then
											estimate[j].Updated = task[count][i][j][n][1]
										elseif task[count][i][j][n][0] == "Period" then
											local period = {[0] = "Period", count = #task[count][i][j][n]}
											-- Loop through all the day plans
											for k = 1,#task[count][i][j][n] do
												period[k] = {[0] = "DP", Date = task[count][i][j][n][k][1][1]}
												if task[count][i][j][n][k][2] == "Hours" then
													period[k].Hours = task[count][i][j][n][k][2][1]
												else
													-- Collect all the time plans
													period[k].TP = {[0]="Time Plan", count = #task[count][i][j][n][k]-1}
													for m = 2,#task[count][i][j][n][k] do
														-- Add this time plan to the kth day plan
														period[k].TP[m-1] = {STA = task[count][i][j][n][k][m][1][1], STP = task[count][i][j][n][k][m][2][1]}
													end
												end
											end		-- for k = 1,#task[count][i][j] do ends
											estimate[j].Period = period
										end		-- if task[count][i][j][0] == "Hours" then ends
									end		-- for n = 1,#task[count][i][j] do ends
								end		-- for j = 1,#task[count][i] do ends
								schedule.Estimate = estimate
							elseif task[count][i][0] == "Committed" then
								local commit = {[0]="Committed"}
								commit.Comment = task[count][i][1][1][1]
								commit.Updated = task[count][i][1][2][1]
								local period = {[0] = "Period", count = #task[count][i][1][3]}
								-- Loop through all the day plans
								for k = 1,#task[count][i][1][3] do
									period[k] = {[0] = "DP", Date = task[count][i][1][3][k][1][1]}
									if task[count][i][1][3][k][2] == "Hours" then
										period[k].Hours = task[count][i][1][3][k][2][1]
									else
										-- Collect all the time plans
										period[k].TP = {[0]="Time Plan", count = #task[count][i][1][3][k]-1}
										for m = 2,#task[count][i][1][3][k] do
											-- Add this time plan to the kth day plan
											period[k].TP[m-1] = {STA = task[count][i][1][3][k][m][1][1], STP = task[count][i][1][3][k][m][2][1]}
										end
									end
								end		-- for k = 1,#task[count][i][j] do ends
								commit.Period = period
								schedule.Commit[1] = commit
							elseif task[count][i][0] == "Revs" then
								local revs = {[0]="Revisions", count = #task[count][i]}
								-- Loop through all the Revisions
								for j = 1,#task[count][i] do
									revs[j] = {[0]="Revision"}
									-- Loop through the children of Revision element
									for n = 1,#task[count][i][j] do
										if task[count][i][j][n][0] == "Comment" then
											revs[j].Comment = task[count][i][j][n][1]
										elseif task[count][i][j][0] == "Updated" then
											revs[j].Updated = task[count][i][j][n][1]
										elseif task[count][i][j][n][0] == "Period" then
											local period = {[0] = "Period", count = #task[count][i][j][n]}
											-- Loop through all the day plans
											for k = 1,#task[count][i][j][n] do
												period[k] = {[0] = "DP", Date = task[count][i][j][n][k][1][1]}
												if task[count][i][j][n][k][2] == "Hours" then
													period[k].Hours = task[count][i][j][n][k][2][1]
												else
													-- Collect all the time plans
													period[k].TP = {[0]="Time Plan", count = #task[count][i][j][n][k]-1}
													for m = 2,#task[count][i][j][n][k] do
														-- Add this time plan to the kth day plan
														period[k].TP[m-1] = {STA = task[count][i][j][n][k][m][1][1], STP = task[count][i][j][n][k][m][2][1]}
													end
												end
											end		-- for k = 1,#task[count][i][j] do ends
											revs[j].Period = period
										end		-- if task[count][i][j][0] == "Hours" then ends
									end		-- for n = 1,#task[count][i][j] do ends
								end		-- for j = 1,#task[count][i] do ends
								schedule.Revs = revs
							elseif task[count][i][0] == "Actual" then
								local actual = {[0]= "Actual", count = #task[count][i]}
								-- Loop through all the work done elements
								for j = 1,actual.count do
									actual[j] = {[0]="Work Done", Date = task[count][i][j][1][1], Hours = task[count][i][j][2][1]}
								end
								schedule.Actual[1] = {Period = actual}
							end							
						end
						dataStruct[dataStruct.tasks].Schedules = schedule
					elseif task[count][0] == "SubTasks" then
						hierInfo[task[count]] = {count = 1, parent = currNode}
						currNode = task[count]
						dataStruct[dataStruct.tasks].SubTasks = {parent = dataStruct, tasks = 0, [0]="SubTasks"}
						dataStruct = dataStruct[dataStruct.tasks].SubTasks
					end
					count = count + 1
				end		-- while(task[count]) do ends
				if necessary < 6 then
					-- this is not valid task
					dataStruct[dataStruct.tasks] = nil
					dataStruct.tasks = dataStruct.tasks - 1
				end
			else
				if currNode[hierInfo[currNode].parent] then
					currNode = hierInfo[currNode].parent
					dataStruct = dataStruct.parent
				end		-- if currNode[hierInfo[level].parent ends here
			end		-- if currNode[hierInfo[level].count][0] == "Task"  ends here
		end
	end		-- while(currNode[hierInfo[level].count]) ends here
	while dataStruct.parent do
		dataStruct = dataStruct.parent
	end
	return dataStruct
end		-- function XML2Data(SporeXML) ends here
