-- Data structure to store the Global Filter Criteria
Filter = {}

-- Function to filter out tasks from the task hierarchy
function applyFilterHier(filter, taskHier)
	local hier = taskHier
	local hierCount = {}
	local returnList = {count = 0}
	-- Reset the hierarchy if not already done so
	while hier.parent do
		hier = hier.parent
	end
	-- Traverse the task hierarchy here
	hierCount[hier] = 0
	while hierCount[hier] < #hier or hier.parent do
		if not(hierCount[hier] < #hier) then
			hier = hier.parent
		else
			-- Increment the counter
			hierCount[hier] = hierCount[hier] + 1
			local passed = validateTask(filter,hier[hierCount[hier]])
			if passed then
				returnList.count = returnList.count + 1
				returnList[returnList.count] = hier[hierCount[hier]]
			end
			if hier[hierCount[hier]].SubTasks then
				-- This task has children so go deeper in the hierarchy
				hier = hier[hierCount[hier]].SubTasks
				hierCount[hier] = 0
			end
		end
	end		-- while hierCount[hier] < #hier or hier.parent do ends here
	return returnList
end

-- Function to filter out tasks from a list of tasks
function applyFilterList(filter, taskList)
	local returnList = {count = 0}
	for i=1,#taskList do
		local passed = validateTask(filter,taskList[i])
		if passed then
			returnList.count = returnList.count + 1
			returnList[returnList.count] = taskList[i]
		end
	end
	return returnList
end

--[[ The Task Filter should filter the following:

1. Tasks - Particular task with out without its children - Specified Task ID, with 'children' flag
2. Who - People responsible for the task (Boolean) - Boolean string with people IDs with their status in single quotes "'milind.gupta,A' or 'aryajur,A' and not('milind_gupta,A' or 'milind0x,I')" - if status not present then taken to be A (Active) 
3. Date_Started - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by ,
4. Date_Finished - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by , 00/00/0000 means no date also passes
5. AccessIDs - Boolean expression of IDs and their access permission - "'milind.gupta,R' or 'aryajur,W' and not('milind_gupta,W' or 'milind0x,W')"
6. Status - Member of given list of status types - List of status types separated by commas
7. Priority - Member of given list of priority types - List of priority numbers separated by commas -"1,2,3"
8. Date_Due - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by , 00/00/0000 means no date also passes
9. Category - Member of given list of Categories - List of categories separated by commas
10. Sub-Category - Member of given list of Sub-Categories - List of sub-categories separated by commas
11. Tags - Boolean expression of Tags - "'Technical' or 'Electronics'" - Tags allow alphanumeric characters spaces and underscores
12. Schedules - Type of matching - Fully Contained or any overlap with the given ranges
		Type of Schedule - Estimate, Committed, Revisions (L=Latest or the number of revision) or Actual or Latest (means the latest schedule, note Actual is only latest if task is marked DONE)
		Boolean expression different schedule criterias together
		"'Full,Estimate(L),12/1/2011-12/5/2011,12/10/2011-1/2/2012' and 'Overlap,Revision(L),12/1/2011-1/2/2012' or 'Full,Estimate(L),00/00/0000'"
		00/00/0000 signifies no schedule for the type of schedule the type of matching is ignored in this case
]]

-- Function to validate a given task
function validateTask(filter, task)
	-- Check if task ID passes
	if filter.Tasks then
		-- Check if the task ID matches
		if filter.Tasks.Children then
			-- Children are allowed
			if filter.Tasks.TaskID ~= string.sub(task.TaskID,1,#filter.Tasks.TaskID) then
				return false
			end
		else
			if filter.Tasks.TaskID ~= task.TaskID then
				return false
			end
		end
	end
	-- Check if Who passes
	if filter.Who then
		local pattern = "%'([%w%.%_%,])+%'"
		local whoStr = filter.Who
		for id in string.gmatch(filter.Who,pattern) do
			-- Check if the Status is given
			local idc = id
			local st = string.find(idc,",")
			local stat
			if st then
				-- Status exists, extract it here
				stat = string.sub(idc,st,-1)
				idc = string.sub(idc,1,st-1)
			else
				stat = "A"
			end
			-- Check if the id exists in the task
			local result = false
			for i = 1,#task.Who do
				if task.Who[i].ID == idc then
					if stat == "A" and string.upper(task.Who[i].Status) == "ACTIVE" then
						result = true
						break
					end
					if stat =="I" and string.upper(task.Who[i].Status) =="INACTIVE" then
						result = true
						break
					end
					result = false
					break
				end		-- if task.Who[i].ID == idc then ends
			end		-- for i = 1,#task.Who ends
			whoStr = string.gsub(whoStr,"'"..id.."'",tostring(result))
		end		-- for id in string.gmatch(filter.Who,pattern) do ends
		-- Check if the boolean passes
		if not loadstring("return "..whoStr)() then
			return false
		end
	end		-- if filter.Who then ends
	
	-- Check if Date Started Passes
	if filter.Start then
		-- Trim the string from leading and trailing spaces
		local strtStr = string.match(filter.Start,"^%s*(.-)%s*$")
		-- Make sure the string has "," both at the beginning and end
		if string.sub(strtStr,1,1) ~= "," then
			strtStr = "," .. strtStr
		end
		if string.sub(strtStr,-1,-1)~="," then
			strtStr = strtStr .. ","
		end
		local matched = false
		for range in string.gmatch(strtStr,",(.-),") do
			-- See if this is a range or a single date
			local strt,stp = string.match(range,"(.-)%-(.*)")
			if not strt then
				-- its not a range
				strt = range
				stp = range
			end
			strt = toXMLDate(strt)
			stp = toXMLDate(stp)
			local taskDate = task.Start
			if strt <= taskDate and taskDate <=stp then
				matched = true
				break
			end
		end
		if not matched then
			return false
		end
	end

	-- Check if Date Finished Passes
	if filter.Fin then
		-- Trim the string from leading and trailing spaces
		local finStr = string.match(filter.Fin,"^%s*(.-)%s*$")
		-- Make sure the string has "," both at the beginning and end
		if string.sub(finStr,1,1) ~= "," then
			finStr = "," .. finStr
		end
		if string.sub(finStr,-1,-1)~="," then
			finStr = finStr .. ","
		end
		local matched = false
		for range in string.gmatch(finStr,",(.-),") do
			-- See if this is a range or a single date
			local strt,stp = string.match(range,"(.-)%-(.*)")
			if not strt then
				-- its not a range
				strt = range
				stp = range
			end
			strt = toXMLDate(strt)
			stp = toXMLDate(stp)
			if task.Fin then
				if strt <= task.Fin and task.Fin <=stp then
					matched = true
					break
				end
			else
				-- No finished date on the task check if strt or stp is 0000-00-00
				if strt == "0000-00-00" or stp == "0000-00-00" then
					matched = true
					break
				end 
			end
		end
		if not matched then
			return false
		end
	end

	-- Check if Access IDs pass
	if filter.Access then
		local pattern = "%'([%w%.%_%,])+%'"
		local accStr = filter.Access
		for id in string.gmatch(filter.Access,pattern) do
			-- Extract the permission character
			local idc = id
			local st = string.find(idc,",")
			local perm

			perm = string.sub(idc,st,-1)
			idc = string.sub(idc,1,st-1)
			
			-- Check if the id exists in the task
			local result = false
			for i = 1,#task.Locked.Access do
				if task.Locked.Access[i].ID == idc then
					if string.upper(perm) == "R" and string.upper(task.Locked.Access[i].Status) == "Read Only" then
						result = true
						break
					end
					if string.upper(perm) =="W" and string.upper(task.Locked.Access[i].Status) =="Read/Write" then
						result = true
						break
					end
					result = false
					break
				end		-- if task.Who[i].ID == idc then ends
			end		-- for i = 1,#task.Who ends
			accStr = string.gsub(accStr,"'"..id.."'",tostring(result))
		end		-- for id in string.gmatch(filter.Who,pattern) do ends
		-- Check if the boolean passes
		if not loadstring("return "..accStr)() then
			return false
		end
	end		-- if filter.Access then ends

	-- Check if Status Passes
	if filter.Status then
		-- Trim the string from leading and trailing spaces
		local statStr = string.match(filter.Status,"^%s*(.-)%s*$")
		-- Make sure the string has "," both at the beginning and end
		if string.sub(statStr,1,1) ~= "," then
			statStr = "," .. statStr
		end
		if string.sub(statStr,-1,-1)~="," then
			statStr = statStr .. ","
		end
		local matched = false
		for stat in string.gmatch(statStr,",(.-),") do
			-- Check if this status matches with what we have in the task
			if task.Status == stat then
				matched = true
				break
			end
		end
		if not matched then
			return false
		end
	end

	-- Check if Priority Passes
	if filter.Priority then
		-- Trim the string from leading and trailing spaces
		local priStr = string.match(filter.Priority,"^%s*(.-)%s*$")
		-- Make sure the string has "," both at the beginning and end
		if string.sub(priStr,1,1) ~= "," then
			priStr = "," .. priStr
		end
		if string.sub(priStr,-1,-1)~="," then
			priStr = priStr .. ","
		end
		local matched = false
		for pri in string.gmatch(priStr,",(.-),") do
			-- Check if this priority matches with what we have in the task
			if task.Priority == pri then
				matched = true
				break
			end
		end
		if not matched then
			return false
		end
	end

	-- Check if Date Due Passes
	if filter.Due then
		-- Trim the string from leading and trailing spaces
		local dueStr = string.match(filter.Due,"^%s*(.-)%s*$")
		-- Make sure the string has "," both at the beginning and end
		if string.sub(dueStr,1,1) ~= "," then
			dueStr = "," .. dueStr
		end
		if string.sub(dueStr,-1,-1)~="," then
			dueStr = dueStr .. ","
		end
		local matched = false
		for range in string.gmatch(dueStr,",(.-),") do
			-- See if this is a range or a single date
			local strt,stp = string.match(range,"(.-)%-(.*)")
			if not strt then
				-- its not a range
				strt = range
				stp = range
			end
			strt = toXMLDate(strt)
			stp = toXMLDate(stp)
			if task.Due then
				if strt <= task.Due and task.Due <=stp then
					matched = true
					break
				end
			else
				-- No Due date on the task check if strt or stp is 0000-00-00
				if strt == "0000-00-00" or stp == "0000-00-00" then
					matched = true
					break
				end 
			end
		end
		if not matched then
			return false
		end
	end

	-- Check if Category Passes
	if filter.Cat then
		-- Trim the string from leading and trailing spaces
		local catStr = string.match(filter.Cat,"^%s*(.-)%s*$")
		-- Make sure the string has "," both at the beginning and end
		if string.sub(catStr,1,1) ~= "," then
			catStr = "," .. catStr
		end
		if string.sub(catStr,-1,-1)~="," then
			catStr = catStr .. ","
		end
		local matched = false
		for cat in string.gmatch(catStr,",(.-),") do
			-- Check if this status matches with what we have in the task
			if task.Cat == cat then
				matched = true
				break
			end
		end
		if not matched then
			return false
		end
	end

	-- Check if Sub-Category Passes
	if filter.SubCat then
		-- Trim the string from leading and trailing spaces
		local subCatStr = string.match(filter.SubCat,"^%s*(.-)%s*$")
		-- Make sure the string has "," both at the beginning and end
		if string.sub(subCatStr,1,1) ~= "," then
			subCatStr = "," .. subCatStr
		end
		if string.sub(subCatStr,-1,-1)~="," then
			subCatStr = subCatStr .. ","
		end
		local matched = false
		for subCat in string.gmatch(subCatStr,",(.-),") do
			-- Check if this status matches with what we have in the task
			if task.SubCat == subCat then
				matched = true
				break
			end
		end
		if not matched then
			return false
		end
	end

	-- Check if Tags pass
	if filter.Tags then
		local pattern = "%'([%w%s%_])+%'"	-- Tags are allowed alphanumeric characters spaces and underscores
		local tagStr = filter.Tags
		for tag in string.gmatch(filter.Tags,pattern) do
			-- Check if the tag exists in the task
			local result = false
			for i = 1,#task.Tags do
				if task.Tags[i] == tag then
					-- Found the tag in the task
					result = true
					break
				end		-- if task.Tags[i] == tag then ends
			end		-- for i = 1,#task.Tags ends
			tagStr = string.gsub(tagStr,"'"..tag.."'",tostring(result))
		end		-- for id in string.gmatch(filter.Tags,pattern) do ends
		-- Check if the boolean passes
		if not loadstring("return "..tagStr)() then
			return false
		end
	end		-- if filter.Access then ends
	
	-- Check if the Schedules pass
	if filter.Schedules then
		schStr = filter.Schedules
		for sch in string.gmatch(filter.Schedules,"%'(.-)%'") do
			-- Check if this schedule chunk passes in the task
			-- "'Full,Estimate,12/1/2011-12/5/2011,12/10/2011-1/2/2012' and 'Overlap,Revision(L),12/1/2011-1/2/2012'"
			local typeMatch, typeSchedule, ranges, rangeStr, index
			local firstComma = string.find(sch,",")
			local secondComma = string.find(sch,",",firstComma + 1)
			typeMatch = string.sub(sch,1,firstComma-1)
			typeSchedule = string.sub(sch,firstComma + 1,secondComma - 1)
			ranges = {[0]=string.sub(sch,secondComma + 1, -1),count=0}
			rangeStr = ranges[0]
			-- Make sure the rangeStr string has "," both at the beginning and end
			if string.sub(rangeStr,1,1) ~= "," then
				rangeStr = "," .. rangeStr
			end
			if string.sub(rangeStr,-1,-1)~="," then
				rangeStr = rangeStr .. ","
			end
			-- Now separate individual date ranges
			for range in string.gmatch(rangeStr,",(.-),") do
				ranges.count = ranges.count + 1
				ranges[count] = range
			end
			-- Type of Schedule - Estimate, Committed, Revision(X) (L=Latest or the number of revision), Actual or Latest (means the latest schedule, note Actual is only latest if task is marked DONE)
			index = nil
			if string.upper(string.sub(typeSchedule,1,#"ESTIMATE")) == "ESTIMATE" then
				if string.match(typeSchedule,"%(%d-%)") then
					-- Get the index number
					index = string.match(typeSchedule,"%((%d-)%)")
				else  
					-- Get the latest schedule index
					index = #task.Schedules.Estimate
				end
				typeSchedule = "Estimate"
			elseif string.upper(typeSchedule) == "COMMITTED" then
				typeSchedule = "Commit"
				index = 1
			elseif string.upper(string.sub(typeSchedule,1,#"REVISION")) == "REVISION" then
				if string.match(typeSchedule,"%(%d-%)") then
					-- Get the index number
					index = string.match(typeSchedule,"%((%d-)%)")
				else  
					-- Get the latest schedule index
					index = #task.Schedules.Revs
				end
				typeSchedule = "Revs"
			elseif string.upper(typeSchedule) == "ACTUAL" then
				typeSchedule = "Actual"
				index = 1
			elseif string.upper(typeSchedule) == "LATEST" then
				-- Find the latest schedule in the task here
				if string.upper(task.Status) == "DONE" and task.Schedules.Actual then
					typeSchedule = "Actual"
					index = 1
				elseif task.Schedules.Revs then
					-- Actual is not the latest one but Revision is 
					typeSchedule = "Revs"
					index = task.Schedule.Revs.count
				elseif task.Schedules.Commit then
					-- Actual and Revisions don't exist but Commit does
					typeSchedule = "Commit"
					index = 1
				elseif task.Schedules.Estimate then
					-- The latest is Estimate
					typeSchedule = "Estimate"
					index = task.Schedules.Estimate.count
				else
					-- typeSchedule is latest but non of the schedule types exist
					-- Check if the range is 00/00/0000, if not this sch is false
					local result = false
					for i = 1,#ranges do
						if ranges[i] == "00/00/0000" then
							result = true
							break
						end
					end
					schStr = string.gsub(schStr,"'"..sch.."'",tostring(result))
				end
			else
				wx.wxMessageBox("Invalid Type Schedule ("..typeSchdule..") specified in filter: "..sch,"Filter Error",
                            wx.wxOK + wx.wxICON_ERROR, GUI.frame)
				return false
			end		-- if string.upper(string.sub(typeSchedule,1,#"ESTIMATE") == "ESTIMATE" then ends  (SETTING of typeSchdule and index)
			if index then
				-- We have a typeSchedule and index
				-- Now loop through the schedule of typeSchedule and index
				local result = false
				-- First check if any range is 00/00/0000 then this schedule should not exist for filter to pass
				for j = 1,#ranges do
					if ranges[j] == "00/00/0000" and not task.Schedules[typeSchedule][index] then
						result = true
						break
					end
				end
				if not result and task.Schedules[typeSchedule][index] then
					for i = 1,#task.Schedules[typeSchedule][index].Period do
						-- Is the date in range?
						local inrange = false
						for j = 1,#ranges do
							local strt,stp = string.match(range,"(.-)%-(.*)")
							if not strt then
								-- its not a range
								strt = range
								stp = range
							end
							strt = toXMLDate(strt)
							stp = toXMLDate(stp)
							if strt <= task.Schedules[typeSchedule][index].Period[i].Date and task.Schedules[typeSchedule][index].Period[i].Date <=stp then
								inrange = true
							end
						end		-- for j = 1,#ranges do ends
						if inrange and string.upper(typeMatch) == "OVERLAP" then
							-- This date overlaps
							result = true
							break
						elseif not inrange and string.upper(typeMatch) == "FULL" then
							-- This portion is not contained in filter
							result = false
							break
						end
					end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends
				end	-- if not result and task.Schedules[typeSchedule][index] then ends
				schStr = string.gsub(schStr,"'"..sch.."'",tostring(result))
			end		-- if index then ends
		end		-- for sch in string.gmatch(filter.Schedules,"%'(.-)%'") do ends
		-- Check if the boolean passes
		if not loadstring("return "..schStr)() then
			return false
		end
	end		-- if filter.Schedules then ends

	-- All pass
	return true
end		-- function validateTask(filter, task) ends
