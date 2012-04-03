-- Table to store all the Spores data 
SporeData = {}

-- Function to convert a boolean string to a Table
-- Table elements '#AND#', '#OR#', '#NOT()#', '#NOT(AND)#' and '#NOT(OR)#' are reserved and their children are the ones 
-- on which this operation is performed.
-- The table consist of a sequence of tables starting from index = 1
-- each sub table has these keys:
-- 1. Item - contains the item name
-- 2. Parent - contains the parent table
-- 3. Children - contains the table similar in hierarchy to the root table
function convertBoolStr2Tab(str)
	local boolTab = {Item="",Parent=nil,Children = {},currChild=nil}
	local strLevel = {[boolTab] = str}
	local subMap = {}
	
	local getUniqueSubst = function(str,subMap)
		if not subMap.latest then
			subMap.latest = 1
		else 
			subMap.latest = subMap.latest + 1
		end
		local uStr = "A"..tostring(subMap.latest)
		local done = false
		while not done do
			-- Check if this exists in str
			while string.find(str,"[%(%s]"..uStr.."[%)%s]") or 
			  string.find(string.sub(str,1,string.len(uStr) + 1),uStr.."[%)%s]") or 
			  string.find(string.sub(str,-(string.len(uStr) + 1),-1),"[%(%s]"..uStr) do
				subMap.latest = subMap.latest + 1
				uStr = "A"..tostring(subMap.latest)
			end
			done = true
			-- Check if the str exists in subMap
			for k,v in pairs(subMap) do
				if k ~= "latest" then
					while string.find(v,"[%(%s]"..uStr.."[%)%s]") or 
					  string.find(string.sub(v,1,string.len(uStr) + 1),uStr.."[%)%s]") or 
					  string.find(string.sub(v,-(string.len(uStr) + 1),-1),"[%(%s]"..uStr) do
						done = false
						subMap.latest = subMap.latest + 1
						uStr = "A"..tostring(subMap.latest)
					end
					if done==false then 
						break 
					end
				end
			end		-- for k,v in pairs(subMap) do ends
		end		-- while not done do ends
		return uStr
	end		-- function getUniqueSubst(str,subMap) ends
	
	local bracketReplace = function(str,subMap)
		-- Function to replace brackets with substitutions and fill up the subMap (substitution map)
		-- Make sure the brackets are consistent
		local _,stBrack = string.gsub(str,"%(","t")
		local _,enBrack = string.gsub(str,"%)","t")
		if stBrack ~= enBrack then
			error("String does not have cosistent opening and closing brackets",2)
		end
		local brack = string.find(str,"%(")
		while brack do
			local init = brack + 1
			local fin
			-- find the ending bracket for this one
			local count = 0	-- to track additional bracket openings
			for i = init,str:len() do
				if string.sub(str,i,i) == "(" then
					count = count + 1
				elseif string.sub(str,i,i) == ")" then
					if count == 0 then
						-- this is the matching bracket
						fin = i-1
						break
					else
						count = count - 1
					end
				end
			end		-- for i = init,str:len() do ends
			local uStr = getUniqueSubst(str,subMap)
			local pre = ""
			local post = ""
			if init > 2 then
				pre = string.sub(str,1,init-2)
			end
			if fin < str:len() - 2 then
				post = string.sub(str,fin + 2,str:len())
			end
			subMap[uStr] = string.sub(str,init,fin)
			str = pre.." "..uStr.." "..post
			-- Now find the next
			local brack = string.find(str,"(")
		end		-- while brack do ends
		str = string.gsub(str,"%s+"," ")		-- Remove duplicate spaces
	end		-- function(str,subMap) ends
	
	local OperSubst = function(str, subMap,op)
		-- Function to make the str a simple OR expression
		op = string.lower(string.match(op,"%s*([%w%W]+)%s*"))
		if not(string.find(str," "..op.." ") or string.find(str," "..string.upper(op).." ")) then
			return str
		end
		str = string.gsub(str," "..string.upper(op).." ", " "..op.." ")
		-- Starting chunk
		local strt,stp,subStr = string.find(str,"(.-) "..op.." ")
		local uStr = getUniqueSubst(str,subMap)
		local newStr = {count = 0} 
		newStr.count = newStr.count + 1
		newStr[newStr.count] = uStr
		subMap[uStr] = subStr
		-- Middle chunks
		strt,stp,subStr = string.find(str," "..op.." (.-) "..op.." ",stp-4)
		while strt do
			uStr = getUniqueSubst(str,subMap)
			newStr.count = newStr.count + 1
			newStr[newStr.count] = uStr
			subMap[uStr] = subStr			
			strt,stp,subStr = string.find(str," "..op.." (.-) "..op.." ",stp-4)	
		end
		-- Last Chunk
		if not stp then
			strt,stp,subStr = string.find(str," "..op.." (.-)$")
		else
			strt,stp,subStr = string.find(str," "..op.." (.-)",stp-4)
		end
		uStr = getUniqueSubst(str,subMap)
		newStr.count = newStr.count + 1
		newStr[newStr.count] = uStr
		subMap[uStr] = subStr
		return newStr
	end		-- local function ORsubst(str) ends
	
	-- Start recursive loop here
	local currTab = boolTab
	while currTab do
		-- Remove all brackets
		if not(strLevel[currTab]) then
			print(currTab.Item)
		end
		strLevel[currTab] = string.gsub(strLevel[currTab],"%s+"," ")
		bracketReplace(strLevel[currTab],subMap)
		-- Check what type of element this is
		if not(string.find(strLevel[currTab]," or ") or string.find(strLevel[currTab]," OR ") 
		  or string.find(strLevel[currTab]," and ") or string.find(strLevel[currTab]," AND ") 
		  or string.find(strLevel[currTab]," not ") or string.find(strLevel[currTab]," NOT ")
		  or string.upper(string.sub(strLevel[currTab],1,4)) == "NOT "
		  or subMap[strLevel[currTab]]) then
			-- This is a simple element
			if currTab.Item == "#NOT()#" then
				currTab.Children[1] = {Item = strLevel[currTab],Parent=currTab}
			else
				currTab.Item = strLevel[currTab]
				currTab.Children = nil
			end
			-- Return one level up
			currTab = currTab.Parent
			while currTab do
				if currTab.currChild < #currTab.Children then
					currTab.currChild = currTab.currChild + 1
					currTab = currTab.Children[currTab.currChild]
					break
				else
					currTab.currChild = nil
					currTab = currTab.Parent
				end
			end
		elseif not(string.find(strLevel[currTab]," or ") or string.find(strLevel[currTab]," OR ") 
		  or string.find(strLevel[currTab]," and ") or string.find(strLevel[currTab]," AND ") 
		  or string.find(strLevel[currTab]," not ") or string.find(strLevel[currTab]," NOT ")
		  or string.upper(string.sub(strLevel[currTab],1,4)) == "NOT ")
		  and subMap[strLevel[currTab]] then
			-- This is a substitution as a whole
			local temp = strLevel[currTab] 
			strLevel[currTab] = subMap[temp]
			subMap[temp] = nil
		else
			-- This is a normal expression
			if string.find(strLevel[currTab]," or ") or string.find(strLevel[currTab]," OR ") then
				-- The expression has OR operators
				-- Transform to a simple OR expression
				local simpStr = OperSubst(strLevel[currTab],subMap,"OR")
				if currTab.Item == "#NOT()#" then
					currTab.Item = "#NOT(OR)#"
				else
					currTab.Item = "#OR#"
				end
				-- Now allchildren need to be added and we must evaluate each child
				for i = 1,#simpStr do
					currTab.Children[#currTab.Children + 1] = {Item="", Parent = currTab,Children={},currChild=nil}
					strLevel[currTab.Children[#currTab.Children]] = simpStr[i]
				end 
				currTab.currChild = 1
				currTab = currTab.Children[1]
			elseif string.find(strLevel[currTab]," and ") or string.find(strLevel[currTab]," AND ") then
				-- The expression does not have OR operators but has AND operators
				-- Transform to a simple AND expression
				local simpStr = OperSubst(strLevel[currTab],subMap,"AND")
				if currTab.Item == "#NOT()#" then
					currTab.Item = "#NOT(AND)#"
				else
					currTab.Item = "#AND#"
				end
				-- Now allchildren need to be added and we must evaluate each child
				for i = 1,#simpStr do
					currTab.Children[#currTab.Children + 1] = {Item="", Parent = currTab,Children={},currChild=nil}
					strLevel[currTab.Children[#currTab.Children]] = simpStr[i]
				end 
				currTab.currChild = 1
				currTab = currTab.Children[1]
			else
				-- This is a NOT element
				strLevel[currTab] = string.gsub(strLevel[currTab],"NOT", "not")
				local elem = string.match(strLevel[currTab],"%s*not%s+([%w%W]+)%s*")
				currTab.Item = "#NOT()#"
				strLevel[currTab] = elem
			end		-- if string.find(strLevel[currTab]," or ") or string.find(strLevel[currTab]," OR ") then ends
		end 
	end		-- while currTab do ends
	return boolTab
end		-- function convertBoolStr2Tab(str) ends



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

-- Function to convert a table to a string
-- Metatables not followed
-- Unless key is a number it will be taken and converted to a string
function tableToString(t)
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)
	rL[rL.cL] = {}
	do
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)
		rL[rL.cL].str = "{"
		rL[rL.cL].t = t
		while true do
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)
			rL[rL.cL]._var = k
			if not k and rL.cL == 1 then
				break
			elseif not k then
				-- go up in recursion level
				if string.sub(rL[rL.cL].str,-1,-1) == "," then
					rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)
				end
				--print("GOING UP:     "..rL[rL.cL].str.."}")
				rL[rL.cL-1].str = rL[rL.cL-1].str..rL[rL.cL].str.."}"
				rL.cL = rL.cL - 1
				rL[rL.cL+1] = nil
				rL[rL.cL].str = rL[rL.cL].str..","
			else
				-- Handle the key and value here
				if type(k) == "number" then
					rL[rL.cL].str = rL[rL.cL].str.."["..tostring(k).."]="
				else
					rL[rL.cL].str = rL[rL.cL].str..tostring(k).."="
				end
				if type(v) == "table" then
					-- Check if this is not a recursive table
					local goDown = true
					for i = 1, rL.cL do
						if v==rL[i].t then
							-- This is recursive do not go down
							goDown = false
							break
						end
					end
					if goDown then
						-- Go deeper in recursion
						rL.cL = rL.cL + 1
						rL[rL.cL] = {}
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)
						rL[rL.cL].str = "{"
						rL[rL.cL].t = v
						--print("GOING DOWN:",k)
					else
						rL[rL.cL].str = rL[rL.cL].str.."\""..tostring(v).."\""
						rL[rL.cL].str = rL[rL.cL].str..","
						--print(k,"=",v)
					end
				elseif type(v) == "number" then
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)
					rL[rL.cL].str = rL[rL.cL].str..","
					--print(k,"=",v)
				else
					rL[rL.cL].str = rL[rL.cL].str.."\""..tostring(v).."\""
					rL[rL.cL].str = rL[rL.cL].str..","
					--print(k,"=",v)
				end		-- if type(v) == "table" then ends
			end		-- if not rL[rL.cL]._var and rL.cL == 1 then ends
		end		-- while true ends here
	end		-- do ends
	if string.sub(rL[rL.cL].str,-1,-1) == "," then
		rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)
	end
	rL[rL.cL].str = rL[rL.cL].str.."}"
	return rL[rL.cL].str
end

function combineDateRanges(range1,range2)
	local comp = compareDateRanges(range1,range2)

	local strt1,fin1 = string.match(range1,"(.-)%-(.*)")
	local strt2,fin2 = string.match(range2,"(.-)%-(.*)")
	
	strt1 = toXMLDate(strt1)
	local idate = XMLDate2wxDateTime(strt1)
	idate = idate:Subtract(wx.wxDateSpan(0,0,0,1))
	local strt1m1 = toXMLDate(idate:Format("%m/%d/%Y"))
	
	fin1 = toXMLDate(fin1)
	idate = XMLDate2wxDateTime(fin1)
	idate = idate:Add(wx.wxDateSpan(0,0,0,1))
	local fin1p1 = toXMLDate(idate:Format("%m/%d/%Y"))

	strt2 = toXMLDate(strt2)

	fin2 = toXMLDate(fin2)

	if comp == 1 then
		return range1
	elseif comp==2 then
		-- range1 lies entirely before range2
		error("Disjoint ranges",2)
	elseif comp==3 then
		-- range1 pre-overlaps range2
		return string.sub(strt1,6,7).."/"..string.sub(strt1,-2,-1).."/"..string.sub(strt1,1,4).."-"..
			string.sub(fin2,6,7).."/"..string.sub(fin2,-2,-1).."/"..string.sub(fin2,1,4)
	elseif comp==4 then
		-- range1 lies entirely inside range2
		return range2
	elseif comp==5 then
		-- range1 post overlaps range2
		return string.sub(strt2,6,7).."/"..string.sub(strt2,-2,-1).."/"..string.sub(strt2,1,4).."-"..
			string.sub(fin1,6,7).."/"..string.sub(fin1,-2,-1).."/"..string.sub(fin1,1,4)
	elseif comp==6 then
		-- range1 lies entirely after range2
		error("Disjoint ranges",2)
	elseif comp==7 then
		-- range2 lies entirely inside range1
			return range1
	end		
end

function XMLDate2wxDateTime(XMLdate)
	local map = {
		[1] = wx.wxDateTime.Jan,
		[2] = wx.wxDateTime.Feb,
		[3] = wx.wxDateTime.Mar,
		[4] = wx.wxDateTime.Apr,
		[5] = wx.wxDateTime.May,
		[6] = wx.wxDateTime.Jun,
		[7] = wx.wxDateTime.Jul,
		[8] = wx.wxDateTime.Aug,
		[9] = wx.wxDateTime.Sep,
		[10] = wx.wxDateTime.Oct,
		[11] = wx.wxDateTime.Nov,
		[12] = wx.wxDateTime.Dec
	}
	return wx.wxDateTimeFromDMY(tonumber(string.sub(XMLdate,-2,-1)),map[tonumber(string.sub(XMLdate,6,7))],tonumber(string.sub(XMLdate,1,4)))
end

--****f* Karm/compareDateRanges
-- FUNCTION
-- Function to compare 2 date ranges
-- 
-- INPUT
-- o range1 -- Date Range 1 eg. 2/25/2012-2/27/2012
-- o range2 -- Date Range 2 eg. 2/25/2012-3/27/2012
-- 
-- RETURNS
-- o 1 -- If date ranges identical
-- o 2 -- If range1 lies entirely before range2
-- o 3 -- If range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2 and not condition 2
-- o 4 -- If range1 lies entirely inside range2
-- o 5 -- If range1 post overlaps range2 i.e. start date of range 1 >= start date of range 2 and start date of range 1 - 1 day <= end date of range 2 and not condition 4 
-- o 6 -- If range1 lies entirely after range2
-- o 7 -- If range2 lies entirely inside range1
-- o nil -- for error
--
-- SOURCE
function compareDateRanges(range1,range2)
--@@END@@
	if not(range1 and range2) or range1=="" or range2=="" then
		error("Expected a valid date range.",2)
	end
	
	if range1 == range2 then
		--  date ranges identical
		return 1
	end
	
	local strt1,fin1 = string.match(range1,"(.-)%-(.*)")
	local strt2,fin2 = string.match(range2,"(.-)%-(.*)")
	
	strt1 = toXMLDate(strt1)
	local idate = XMLDate2wxDateTime(strt1)
	idate = idate:Subtract(wx.wxDateSpan(0,0,0,1))
	local strt1m1 = toXMLDate(idate:Format("%m/%d/%Y"))
	
	fin1 = toXMLDate(fin1)
	idate = XMLDate2wxDateTime(fin1)
	idate = idate:Add(wx.wxDateSpan(0,0,0,1))
	local fin1p1 = toXMLDate(idate:Format("%m/%d/%Y"))
	
	strt2 = toXMLDate(strt2)
	
	fin2 = toXMLDate(fin2)
	
	if strt1>fin1 or strt2>fin2 then
		error("Range given is not valid. Start date should be less than finish date.",2)
	end
	
	if fin1p1<strt2 then
		-- range1 lies entirely before range2
		return 2
	elseif fin1<=fin2 and strt1<strt2 then
		-- range1 pre-overlaps range2
		return 3
	elseif strt1>strt2 and fin1<fin2 then
		-- range1 lies entirely inside range2
		return 4
	elseif strt1m1<=fin2 and strt1>=strt2 then
		-- range1 post overlaps range2
		return 5
	elseif strt1m1>fin2 then
		-- range1 lies entirely after range2
		return 6
	elseif strt1<strt2 and fin1>fin2 then
		-- range2 lies entirely inside range1
		return 7
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

function addItemToArray(item,array)
	local pos = 0
	for i = 1,#array do
		if array[i] == item  then
			return array
		end
		if array[i]>item then
			pos = i
			break
		end
	end
	if pos == 0 then
		-- place item in the end
		array[#array+1] = item
		return array
	end
	local newarray = {}
	for i = 1,pos-1 do
		newarray[i] = array[i]
	end
	newarray[pos] = item
	for i = pos,#array do
		newarray[i+1] = array[i]
	end
	return newarray
end

-- Function to collect and return all data from the task heirarchy on the basis of which task filtration criteria can be selected
function collectFilterData(filterData, taskHier)
	local hier = taskHier
	local hierCount = {}
	-- Reset the hierarchy if not already done so
	while hier.parent do
		hier = hier.parent
	end
	-- Traverse the task hierarchy here
	hierCount[hier] = 0
	while hierCount[hier] < #hier or hier.parent do
		if not(hierCount[hier] < #hier) then
			if hier == taskHier then
				-- Do not go above the passed task
				break
			end 
			hier = hier.parent
		else
			-- Increment the counter
			hierCount[hier] = hierCount[hier] + 1
			-- Who data
			for i = 1,#hier[hierCount[hier]].Who do
				filterData.Who = addItemToArray(hier[hierCount[hier]].Who[i].ID,filterData.Who)
			end
			-- Access Data
			if string.upper(hier[hierCount[hier]].Locked.Status) == "YES" and hier[hierCount[hier]].Locked.Access then
				for i = 1,#hier[hierCount[hier]].Locked.Access do
					filterData.Access = addItemToArray(hier[hierCount[hier]].Locked.Access[i].ID,filterData.Access)
				end
			end
			-- Priority Data
			if hier[hierCount[hier]].Priority then
				filterData.Priority = addItemToArray(hier[hierCount[hier]].Priority,filterData.Priority)
			end			
			-- Category Data
			if hier[hierCount[hier]].Cat then
				filterData.Cat = addItemToArray(hier[hierCount[hier]].Cat,filterData.Cat)
			end			
			-- Sub-Category Data
			if hier[hierCount[hier]].SubCat then
				filterData.SubCat = addItemToArray(hier[hierCount[hier]].SubCat,filterData.SubCat)
			end			
			-- Tags Data
			if hier[hierCount[hier]].Tags then
				for i = 1,#hier[hierCount[hier]].Tags do
					filterData.Tags = addItemToArray(hier[hierCount[hier]].Tags[i],filterData.Tags)
				end
			end
			if hier[hierCount[hier]].SubTasks then
				-- This task has children so go deeper in the hierarchy
				hier = hier[hierCount[hier]].SubTasks
				hierCount[hier] = 0
			end
		end
	end		-- while hierCount[hier] < #hier or hier.parent do ends here
end

-- Function to convert XML data from a single spore to internal data structure
function XML2Data(SporeXML, SporeFile)
	-- tasks counts the number of tasks at the current level
	-- index 0 contains the name of this level to make it compatible with LuaXml
	local dataStruct = {tasks = 0, [0] = "Task_Spore",filterData = {Who={},Access={},Priority={},Cat={},SubCat={},Tags={}}}	-- to create the data structure
	local filterData = dataStruct.filterData
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
							filterData.Who = addItemToArray(WhoTable[i].ID,filterData.Who)
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
									filterData.Access = addItemToArray(AccessTable[i].ID,filterData.Access)
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
						filterData.Priority = addItemToArray(task[count][1],filterData.Priority)
					elseif task[count][0] == "Due" then
						dataStruct[dataStruct.tasks].Due = task[count][1]
					elseif task[count][0] == "Comments" then
						dataStruct[dataStruct.tasks].Comments = task[count][1]
					elseif task[count][0] == "Category" then
						dataStruct[dataStruct.tasks].Cat = task[count][1]
						filterData.Cat = addItemToArray(task[count][1],filterData.Cat)
					elseif task[count][0] == "Sub-Category" then
						dataStruct[dataStruct.tasks].SubCat = task[count][1]
						filterData.SubCat = addItemToArray(task[count][1],filterData.SubCat)
					elseif task[count][0] == "Tags" then
						local tagTable = {[0]="Tags", count = #task[count]}
						-- Loop through all the items in the Tags element
						for i = 1,#task[count] do
							tagTable[i] = task[count][i][1]
							filterData.Tags = addItemToArray(tagTable[i],filterData.Tags)
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
