-- Table to store all the Spores data 
SporeData = {}

-- Function to convert a boolean string to a Table
-- Table elements '#AND#', '#OR#', '#NOT()#', '#NOT(AND)#' and '#NOT(OR)#' are reserved and their children are the ones 
-- on which this operation is performed.
-- The table consist of:
-- 1. Item - contains the item name
-- 2. Parent - contains the parent table
-- 3. Children - contains a sequence of tables starting from index = 1 similar to the root table
local function convertBoolStr2Tab(str)
	local boolTab = {Item="",Parent=nil,Children = {},currChild=nil}
	local strLevel = {}
	local subMap = {}
	
	local getUniqueSubst = function(str,subMap)
		if not subMap.latest then
			subMap.latest = 1
		else 
			subMap.latest = subMap.latest + 1
		end
		-- Generate prospective nique string
		local uStr = "A"..tostring(subMap.latest)
		local done = false
		while not done do
			-- Check if this unique string exists in str
			while string.find(str,"[%(%s]"..uStr.."[%)%s]") or 
			  string.find(string.sub(str,1,string.len(uStr) + 1),uStr.."[%)%s]") or 
			  string.find(string.sub(str,-(string.len(uStr) + 1),-1),"[%(%s]"..uStr) do
				subMap.latest = subMap.latest + 1
				uStr = "A"..tostring(subMap.latest)
			end
			done = true
			-- Check if the str exists in subMap mappings already replaced
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
			error("String does not have consistent opening and closing brackets",2)
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
			if count ~= 0 then
				error("String does not have consistent opening and closing brackets",2)
			end
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
			brack = string.find(str,"%(")
		end		-- while brack do ends
		str = string.gsub(str,"%s+"," ")		-- Remove duplicate spaces
		str = string.match(str,"^%s*(.-)%s*$")
		return str
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
		strt,stp,subStr = string.find(str," "..op.." (.-) "..op.." ",stp-op:len()-1)
		while strt do
			uStr = getUniqueSubst(str,subMap)
			newStr.count = newStr.count + 1
			newStr[newStr.count] = uStr
			subMap[uStr] = subStr			
			strt,stp,subStr = string.find(str," "..op.." (.-) "..op.." ",stp-op:len()-1)	
		end
		-- Last Chunk
		strt,stp,subStr = string.find(str,"^.+ "..op.." (.-)$")
		uStr = getUniqueSubst(str,subMap)
		newStr.count = newStr.count + 1
		newStr[newStr.count] = uStr
		subMap[uStr] = subStr
		return newStr
	end		-- local function ORsubst(str) ends
	
	-- First replace all quoted strings in the string with substitutions
	local strSubMap = {}
	local _,numQuotes = string.gsub(str,"%'","t")
	if numQuotes%2 ~= 0 then
		error("String does not have consistent opening and closing quotes \"'\"",2)
	end
	local init,fin = string.find(str,"'.-'")
	while init do
		local uStr = getUniqueSubst(str,subMap)
		local pre = ""
		local post = ""
		if init > 1 then
			pre = string.sub(str,1,init-1)
		end
		if fin < str:len() then
			post = string.sub(str,fin + 1,str:len())
		end
		strSubMap[uStr] = str:sub(init,fin)
		str = pre.." "..uStr.." "..post
		-- Now find the next
		init,fin = string.find(str,"'.-'")
	end		-- while brack do ends
	strLevel[boolTab] = str
	-- Start recursive loop here
	local currTab = boolTab
	while currTab do
		-- Remove all brackets
		strLevel[currTab] = string.gsub(strLevel[currTab],"%s+"," ")
		strLevel[currTab] = bracketReplace(strLevel[currTab],subMap)
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
	-- Now recurse boolTab to substitute all the strings back
	local t = boolTab
	if strSubMap[t.Item] then
		t.Item = string.match(strSubMap[t.Item],"'(.-)'")
	end
	if t.Children then
		-- Traverse the table to fill up the tree
		local tIndex = {}
		tIndex[t] = 1
		while tIndex[t] <= #t.Children or t.Parent do
			if tIndex[t] > #t.Children then
				tIndex[t] = nil
				t = t.Parent
			else
				-- Handle the current element
				if strSubMap[t.Children[tIndex[t]].Item] then
					t.Children[tIndex[t]].Item = strSubMap[t.Children[tIndex[t]].Item]:match("'(.-)'")
				end
				tIndex[t] = tIndex[t] + 1
				-- Check if this has children
				if t.Children[tIndex[t]-1].Children then
					-- go deeper in the hierarchy
					t = t.Children[tIndex[t]-1]
					tIndex[t] = 1
				end
			end		-- if tIndex[t] > #t then ends
		end		-- while tIndex[t] <= #t and t.Parent do ends
	end	-- if t.Children then ends
	return boolTab
end		-- function convertBoolStr2Tab(str) ends

function getTaskSummary(task)
	if task then
		local taskSummary = ""
		if task.TaskID then
			taskSummary = "ID: "..task.TaskID
		end
		if task.Title then
			taskSummary = taskSummary.."\nTITLE: "..task.Title
		end
		if task.Start then
			taskSummary = taskSummary.."\nSTART DATE: "..task.Start
		end
		if task.Fin then
			taskSummary = taskSummary.."\nFINISH DATE: "..task.Fin
		end
		if task.Status then
			taskSummary = taskSummary.."\nSTATUS: "..task.Status
		end
		-- Responsible People
		if task.Who then
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
		end
		if task.Access then
			taskSummary = taskSummary.."\nLOCKED: YES"
			local RA = ""
			local RWA = ""
			for i = 1,task.Access.count do
				if string.upper(task.Access[i].Status) == "READ ONLY" then
					RA = RA..","..task.Access[i].ID
				else
					RWA = RWA..","..task.Access[i].ID
				end
			end
			if #RA > 0 then
				taskSummary = taskSummary.."\n   READ ACCESS PEOPLE: "..string.sub(RA,2,-1)
			end
			if #RWA > 0 then
				taskSummary = taskSummary.."\n   READ/WRITE ACCESS PEOPLE: "..string.sub(RWA,2,-1)
			end
		end
		if task.Cat then
			taskSummary = taskSummary.."\nCATEGORY: "..task.Cat
		end
		if task.SubCat then
			taskSummary = taskSummary.."\nSUB-CATEGORY: "..task.SubCat
		end
		if task.Comments then
			taskSummary = taskSummary.."\nCOMMENTS:\n"..task.Comments
		end
		return taskSummary
	else
		return "No Task Selected"
	end
end

function getWorkDoneDates(task)
	if task.Schedules then
		if task.Schedules.Actual then
			local dateList = {}
			for i = 1,#task.Schedules["Actual"][1].Period do
				dateList[#dateList + 1] = task.Schedules["Actual"][1].Period[i].Date
			end		-- for i = 1,#task.Schedules["Actual"][1].Period do ends
			dateList.typeSchedule = "Actual"
			dateList.index = 1
			return dateList
		else 
			return nil
		end
	else 
		return nil		
	end		-- if task.Schedules then ends
end
-- Function to get the list of dates in the latest schedule of the task.
-- if planning == true then the planning schedule dates are returned
function getLatestScheduleDates(task,planning)
	local typeSchedule, index
	local dateList = {}
	if planning then
		if task.Planning and task.Planning.Period then
			for i = 1,#task.Planning.Period do
				dateList[#dateList + 1] = task.Planning.Period[i].Date
			end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends
			dateList.typeSchedule = task.Planning.Type
			dateList.index = task.Planning.index
			return dateList
		else
			return nil
		end
	else
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
			elseif task.Schedules.Estimate then
				-- The latest is Estimate
				typeSchedule = "Estimate"
				index = task.Schedules.Estimate.count
			else
				-- task.Schedules can exist if only Actual exists  but task is not DONE yet
				return nil
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
	end		-- if planning then ends
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

-- Creates lua code for a table which when executed will create a table t0 which would be the same as the originally passed table
-- Handles the following types for keys and values:
-- Keys: Number, String, Table
-- Values: Number, String, Table, Boolean
-- It also handles recursive and interlinked tables to recreate them back
function tableToString2(t)
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)
	rL[rL.cL] = {}
	local tabIndex = {}	-- Table to store a list of tables indexed into a string and their variable name
	local latestTab = 0
	do
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)
		rL[rL.cL].str = "t0={}"	-- t0 would be the main table
		rL[rL.cL].t = t
		rL[rL.cL].tabIndex = 0
		tabIndex[t] = rL[rL.cL].tabIndex
		while true do
			local key
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)
			rL[rL.cL]._var = k
			if not k and rL.cL == 1 then
				break
			elseif not k then
				-- go up in recursion level
				--print("GOING UP:     "..rL[rL.cL].str.."}")
				rL[rL.cL-1].str = rL[rL.cL-1].str.."\n"..rL[rL.cL].str
				rL.cL = rL.cL - 1
				if rL[rL.cL].vNotDone then
					-- This was a key recursion so add the key string and then doV
					key = "t"..rL[rL.cL].tabIndex.."[t"..tostring(rL[rL.cL+1].tabIndex).."]"
					rL[rL.cL].str = rL[rL.cL].str.."\n"..key.."="
					v = rL[rL.cL].vNotDone
				end
				rL[rL.cL+1] = nil
			else
				-- Handle the key and value here
				if type(k) == "number" then
					key = "t"..rL[rL.cL].tabIndex.."["..tostring(k).."]"
					rL[rL.cL].str = rL[rL.cL].str.."\n"..key.."="
				elseif type(k) == "string" then
					key = "t"..rL[rL.cL].tabIndex.."."..tostring(k)
					rL[rL.cL].str = rL[rL.cL].str.."\n"..key.."="
				else
					-- Table key
					-- Check if the table already exists
					if tabIndex[k] then
						key = "t"..rL[rL.cL].tabIndex.."[t"..tabIndex[k].."]"
						rL[rL.cL].str = rL[rL.cL].str.."\n"..key.."="
					else
						-- Go deeper to stringify this table
						latestTab = latestTab + 1
						rL[rL.cL].str = rL[rL.cL].str.."\nt"..tostring(latestTab).."={}"	-- New table
						rL[rL.cL].vNotDone = v
						rL.cL = rL.cL + 1
						rL[rL.cL] = {}
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(k)
						rL[rL.cL].tabIndex = latestTab
						rL[rL.cL].t = k
						rL[rL.cL].str = ""
						tabIndex[k] = rL[rL.cL].tabIndex
					end		-- if tabIndex[k] then ends
				end		-- if type(k)ends
			end		-- if not k and rL.cL == 1 then ends
			if key then
				rL[rL.cL].vNotDone = nil
				if type(v) == "table" then
					-- Check if this table is already indexed
					if tabIndex[v] then
						rL[rL.cL].str = rL[rL.cL].str.."t"..tabIndex[v]
					else
						-- Go deeper in recursion
						latestTab = latestTab + 1
						rL[rL.cL].str = rL[rL.cL].str.."{}" 
						rL[rL.cL].str = rL[rL.cL].str.."\nt"..tostring(latestTab).."="..key	-- New table
						rL.cL = rL.cL + 1
						rL[rL.cL] = {}
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)
						rL[rL.cL].tabIndex = latestTab
						rL[rL.cL].t = v
						rL[rL.cL].str = ""
						tabIndex[v] = rL[rL.cL].tabIndex
						--print("GOING DOWN:",k)
					end
				elseif type(v) == "number" then
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)
					--print(k,"=",v)
				elseif type(v) == "boolean" then
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)				
				else
					rL[rL.cL].str = rL[rL.cL].str..string.format("%q",tostring(v))
					--print(k,"=",v)
				end		-- if type(v) == "table" then ends
			end		-- if doV then ends
		end		-- while true ends here
	end		-- do ends
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

function getWeekDay(xmlDate)
	if #xmlDate ~= 10 then
		error("Expected XML Date in the form YYYY-MM-DD",2)
	end
	local WeekDays = {"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"}
	-- Using the Gauss Formula
	-- http://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week#Gaussian_algorithm
	local d = tonumber(xmlDate:sub(-2,-1))
	local m = tonumber(xmlDate:sub(6,7))
	m = (m + 9)%12 + 1
	local Y
	if m > 10 then
		Y = string.match(tostring(tonumber(xmlDate:sub(1,4)) - 1),"%d+")
		Y = string.rep("0",4-#Y)..Y
	else
		Y = xmlDate:sub(1,4)
	end
	local y = tonumber(Y:sub(-2,-1))
	local c = tonumber(Y:sub(1,2))
	local w = (d + (2.6*m-0.2)-(2.6*m-0.2)%1 + y + (y/4)-(y/4)%1 + (c/4)-(c/4)%1-2*c)%7+1
	return WeekDays[w]
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
function collectFilterDataHier(filterData, taskHier)
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
			collectFilterData(filterData,hier[hierCount[hier]])
			if hier[hierCount[hier]].SubTasks then
				-- This task has children so go deeper in the hierarchy
				hier = hier[hierCount[hier]].SubTasks
				hierCount[hier] = 0
			end
		end
	end		-- while hierCount[hier] < #hier or hier.parent do ends here
end

function collectFilterDataList(filterData,taskList)
	for i=1,#taskList do
		collectFilterData(filterData,taskList[i])
	end
end

-- Copied from http://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
function copyTable(t, deep, seen)
    seen = seen or {}
    if t == nil then return nil end
    if seen[t] then return seen[t] end

    local nt = {}
    for k, v in pairs(t) do
        if deep and type(v) == 'table' then
            nt[k] = copyTable(v, deep, seen)
        else
            nt[k] = v
        end
    end
    setmetatable(nt, copyTable(getmetatable(t), deep, seen))
    seen[t] = nt
    return nt
end

-- Function to make a copy of a task (Sub tasks are not copied they are still the same tables)
-- DBDATA table is also the same linked table
function copyTask(task)
	if not task then
		return
	end
	local nTask = {}
	for k,v in pairs(task) do
		if k ~= "Who" and k ~= "Schedules" and k~= "Tags" and k ~= "Access" and k ~= "Assignee" then
			nTask[k] = task[k]
		else
			nTask[k] = copyTable(task[k],true)
		end
	end		-- for k,v in pairs(task) do ends
	return nTask
end		-- function copyTask(task)ends

-- Function to convert a task to a task list with incremental schedules i.e. 1st will be same as task passed (but a copy of it) and last task will have 1st schedule only
-- The task ID however have additional _n where n is a serial number from 1 
function task2IncSchTasks(task)
	local taskList = {}
	taskList[1] = copyTask(task)
	taskList[1].TaskID = taskList[1].TaskID.."_1"
	while taskList[#taskList].Schedules do
		-- Find the latest schedule in the task here
		if string.upper(taskList[#taskList].Status) == "DONE" and taskList[#taskList].Schedules.Actual then
			-- Actual Schedule is the latest so remove this one
			taskList[#taskList + 1] = copyTask(taskList[#taskList])
			-- Remove the actual schedule
			taskList[#taskList].Schedules.Actual = nil
			-- Change the task ID
			taskList[#taskList].TaskID = task.TaskID.."_"..tostring(#taskList)
		elseif taskList[#taskList].Schedules.Revs then
			-- Actual is not the latest one but Revision is 
			taskList[#taskList + 1] = copyTask(taskList[#taskList])
			-- Remove the latest Revision Schedule
			taskList[#taskList].Schedules.Revs[taskList[#taskList].Schedules.Revs.count] = nil
			taskList[#taskList].Schedules.Revs.count = taskList[#taskList].Schedules.Revs.count - 1
			if taskList[#taskList].Schedules.Revs.count == 0 then
				taskList[#taskList].Schedules.Revs = nil
			end
			-- Change the task ID
			taskList[#taskList].TaskID = task.TaskID.."_"..tostring(#taskList)
		elseif taskList[#taskList].Schedules.Commit then
			-- Actual and Revisions don't exist but Commit does
			taskList[#taskList + 1] = copyTask(taskList[#taskList])
			-- Remove the Commit Schedule
			taskList[#taskList].Schedules.Commit = nil
			-- Change the task ID
			taskList[#taskList].TaskID = task.TaskID.."_"..tostring(#taskList)
		elseif taskList[#taskList].Schedules.Estimate then
			-- The latest is Estimate
			taskList[#taskList + 1] = copyTask(taskList[#taskList])
			-- Remove the latest Estimate Schedule
			taskList[#taskList].Schedules.Estimate[taskList[#taskList].Schedules.Estimate.count] = nil
			taskList[#taskList].Schedules.Estimate.count = taskList[#taskList].Schedules.Estimate.count - 1
			if taskList[#taskList].Schedules.Estimate.count == 0 then
				taskList[#taskList].Schedules.Estimate = nil
			end
			-- Change the task ID
			taskList[#taskList].TaskID = task.TaskID.."_"..tostring(#taskList)
		elseif not taskList[#taskList].Schedules.Estimate and not taskList[#taskList].Schedules.Commit
		  and not taskList[#taskList].Schedules.Revs then
		  	-- Since there can be an Actual Schedule but task is not done so Schedules cannot be nil
		  	break
		end
		if not taskList[#taskList].Schedules.Estimate and not taskList[#taskList].Schedules.Commit 
		  and not taskList[#taskList].Schedules.Revs and not taskList[#taskList].Schedules.Actual then
			taskList[#taskList].Schedules = nil
		end
	end			-- while taskList[#taskList].Schedules do ends
	taskList[#taskList] = nil
	return taskList
end		-- function task2IncSchTasks(task) ends

-- Function to return an Empty task that satisfies the minimum requirements
function getEmptyTask(SporeFile)
	local nTask = {}
	nTask[0] = "Task"
	nTask.SporeFile = SporeFile
	nTask.Title = "DUMMY"
	nTask.TaskID = "DUMMY"
	nTask.Start = "1900-01-01"
	nTask.Public = true
	nTask.Who = {[0] = "Who", count = 1,[1] = "DUMMY"}
	nTask.Status = "Not Started"
	
	return nTask
end

-- Function to cycle the planning schedule type for a task
-- This function depends on the task setting methodology chosen to be in the sequence of Estimate->Commit->Revs->Actual
-- So conversions are:
-- Nothing->Estimate
-- Estimate->Commit
-- Commit->Revs
-- Revs->Actual
-- Actual->Back to Estimate
function togglePlanningType(task,type)
	if not task.Planning then
		task.Planning = {}
	end
	if type == "NORMAL" then
		local dateList = getLatestScheduleDates(task)
		if not dateList then
			dateList = {}
			dateList.index = 0
			dateList.typeSchedule = "Estimate"
		end
				
		if not task.Planning.Type then
			if dateList.typeSchedule == "Estimate" then
				task.Planning.Type = "Estimate"
				task.Planning.index = dateList.index + 1
			elseif dateList.typeSchedule == "Commit" then
				task.Planning.Type = "Revs"
				task.Planning.index = 1
			elseif dateList.typeSchedule == "Revs" then
				task.Planning.Type = "Revs"
				task.Planning.index = dateList.index + 1
			else
				task.Planning.Type = "Actual"
				task.Planning.index = 1		
			end
		elseif task.Planning.Type == "Estimate" then
			task.Planning.Type = "Commit"
			task.Planning.index = 1
		elseif task.Planning.Type == "Commit" then
			task.Planning.Type = "Revs"
			if task.Schedules and task.Schedules.Revs then
				task.Planning.index = #task.Schedules.Revs + 1
			else
				task.Planning.index = 1
			end
		elseif task.Planning.Type == "Revs" then
			-- in "NORMAL" type the schedule does not go to "Actual"
			task.Planning.Type = "Estimate"
			if task.Schedules and task.Schedules.Estimate then
				task.Planning.index = #task.Schedules.Estimate + 1
			else
				task.Planning.index = 1
			end
		end		-- if not task.Planning.Type then ends
	else
		task.Planning.Type = "Actual"
		task.Planning.index = 1
	end		-- if type == "NORMAL" then ends
end


-- Function to toggle a planning date in the given task. If the planning schedule table is not present it creates it with the schedule type Estimate
-- returns 1 if added, 2 if removed, 3 if removed and no more planning schedule left
function togglePlanningDate(task,xmlDate,type)
	if not task.Planning then
		togglePlanningType(task,type)
		task.Planning.Period = {
									[0]="Period",
									count=1,
									[1]={
											[0]="DP",
											Date = xmlDate
										}
								}
		
		return 1
	end
	if not task.Planning.Period then
		task.Planning.Period = {
									[0]="Period",
									count=1,
									[1]={
											[0]="DP",
											Date = xmlDate
										}
								}
		
		return 1
	end
	for i=1,task.Planning.Period.count do
		if task.Planning.Period[i].Date == xmlDate then
			-- Remove this date
			for j=i+1,task.Planning.Period.count do
				task.Planning.Period[j-1] = task.Planning.Period[j]
			end
			task.Planning.Period[task.Planning.Period.count] = nil
			task.Planning.Period.count = task.Planning.Period.count - 1
			if task.Planning.Period.count>0 then
				return 2
			else
				task.Planning = nil
				return 3
			end
		elseif task.Planning.Period[i].Date > xmlDate then
			-- Insert Date here
			task.Planning.Period.count = task.Planning.Period.count + 1
			for j = task.Planning.Period.count,i+1,-1 do
				task.Planning.Period[j] = task.Planning.Period[j-1]
			end
			task.Planning.Period[i] = {[0]="DP",Date=xmlDate}
			return 1
		end
	end
	-- Date must be added in the end
	task.Planning.Period.count = task.Planning.Period.count + 1
	task.Planning.Period[task.Planning.Period.count] = {[0]="DP",Date = xmlDate	}
	return 1
end

function addTask2Spore(task,dataStruct)
	dataStruct.tasks = dataStruct.tasks + 1
	dataStruct[dataStruct.tasks] = task 
	--collectFilterData(dataStruct.filterData,task)
end

function getNewChildTaskID(parent)
	local taskID
	if not parent.SubTasks then
		taskID = parent.TaskID.."_1"
	else 
		local intVar1 = 0
		for count = 1,#parent.SubTasks do
	        local tempTaskID = parent.SubTasks[count].TaskID
	        if tonumber(tempTaskID:sub(-(#tempTaskID - #parent.TaskID - 1),-1)) > intVar1 then
	            intVar1 = tonumber(tempTaskID:sub(-(#tempTaskID - #parent.TaskID - 1),-1))
	        end
		end
		intVar1 = intVar1 + 1
		taskID = parent.TaskID.."_"..tostring(intVar1)
	end
	return taskID
end

-- Function to add a task according to the specified relation
function addTask2Parent(task, parent, Spore)
	if not (task and parent) then
		error("nil parameter cannot be handled at addTask2Parent in DataHandler.lua.",2)
	end
	if not parent.SubTasks then
		parent.SubTasks = {tasks = 0, [0]="SubTasks"}
		if not parent.Parent then
			if not Spore then
				error("nil parameter cannot be handled at addTask2Parent in DataHandler.lua.",2)
			end
			-- This is a Spore root node
			parent.SubTasks.parent = Spore
		else
			parent.SubTasks.parent = parent.Parent.SubTasks
		end 
	end
	parent.SubTasks.tasks = parent.SubTasks.tasks + 1
	parent.SubTasks[parent.SubTasks.tasks] = task
end

-- function to update the taskID in the whole hierarchy
function updateTaskID(task,taskID)
	if not(task and taskID) then
		error("Need a task and taskID for updateTaskID in DataHandler.lua",2)
	end
	local prevTaskID = task.TaskID
	task.TaskID = taskID
	if task.SubTasks then
		local currNode = task.SubTasks
		local hierCount = {}
		-- Traverse the task hierarchy here
		hierCount[currNode] = 0
		while hierCount[currNode] < #currNode or currNode.parent do
			if not(hierCount[currNode] < #currNode) then
				if currNode == task.SubTasks then
					-- Do not go above the passed task
					break
				end 
				currNode = currNode.parent
			else
				-- Increment the counter
				hierCount[currNode] = hierCount[currNode] + 1
				currNode[hierCount[currNode]].TaskID = currNode[hierCount[currNode]].TaskID:gsub("^"..prevTaskID,task.TaskID)
				if currNode[hierCount[currNode]].SubTasks then
					-- This task has children so go deeper in the hierarchy
					currNode = currNode[hierCount[currNode]].SubTasks
					hierCount[currNode] = 0
				end
			end
		end		-- while hierCount[hier] < #hier or hier.parent do ends here
	end		-- if task.SubTasks then ends
end

-- Function to move the task before/after
function bubbleTask(task,relative,beforeAfter,parent)
	if task.Parent ~= relative.Parent then
		error("The task and relative should be on the same level in the bubbleTask call in DataHandler.lua",2)
	end
	if not (task.Parent or parent) then
		error("parent argument should be specified for tasks/relative that do not have a parent defined in bubbleTask call in DataHandler.lua",2)
	end	
	if task==relative then
		return
	end
	local pTable, swapID
	if not task.Parent then
		-- These are root nodes in a spore
		pTable = parent
		swapID = false	-- since IDs for spore root nodes should not be swapped since they are roots and unique
	else
		pTable = relative.Parent.SubTasks
		swapID = true
	end
	if beforeAfter:upper() == "AFTER" then
		-- Next Sibling
		-- Find the relative and task number
		local posRel, posTask
		for i = 1,pTable.tasks do
			if pTable[i] == relative then
				posRel = i
			end
			if pTable[i] == task then
				posTask = i
			end
		end
		if posRel < posTask then
			-- Start the bubble up 
			for i = posTask,posRel+2,-1 do
				if swapID then
					-- Swap TaskID
					local tim1 = pTable[i].TaskID
					local ti = pTable[i-1].TaskID
					updateTaskID(pTable[i],ti) 
					updateTaskID(pTable[i-1],tim1)
				end 
				-- Swap task position
				pTable[i],pTable[i-1] = pTable[i-1],pTable[i]
			end
		else
			-- Start the bubble down 
			for i = posTask,posRel-1 do
				if swapID then
					-- Swap TaskID
					local tip1 = pTable[i].TaskID
					local ti = pTable[i+1].TaskID
					updateTaskID(pTable[i],ti) 
					updateTaskID(pTable[i+1],tip1)
				end 
				-- Swap task position
				pTable[i],pTable[i+1] = pTable[i+1],pTable[i]
			end
		end
	else
		-- Previous sibling
		-- Find the relative and task number
		local posRel, posTask
		for i = 1,pTable.tasks do
			if pTable[i] == relative then
				posRel = i
			end
			if pTable[i] == task then
				posTask = i
			end
		end
		if posRel < posTask then
			-- Start the bubble up 
			for i = posTask,posRel+1,-1 do
				if swapID then
					-- Swap TaskID
					local tim1 = pTable[i].TaskID
					local ti = pTable[i-1].TaskID
					updateTaskID(pTable[i],ti) 
					updateTaskID(pTable[i-1],tim1)
				end 
				-- Swap task position
				pTable[i],pTable[i-1] = pTable[i-1],pTable[i]
			end
		else
			-- Start the bubble down 
			for i = posTask,posRel-2 do
				if swapID then
					-- Swap TaskID
					local tip1 = pTable[i].TaskID
					local ti = pTable[i+1].TaskID
					updateTaskID(pTable[i],ti) 
					updateTaskID(pTable[i+1],tip1)
				end 
				-- Swap task position
				pTable[i],pTable[i+1] = pTable[i+1],pTable[i]
			end
		end
	end

end

function DeleteTaskFromSpore(task, Spore)
	if task.Parent then
		error("DeleteTaskFromSpore: Cannot delete task that is not a root task in Spore.",2)
	end
	local taskList
	taskList = Spore
	for i = 1,#taskList do
		if taskList[i] == task then
			for j = i, #taskList-1 do
				taskList[j] = taskList[j+1]
			end
			taskList[#taskList] = nil
			taskList.tasks = taskList.tasks - 1
			break
		end
	end
end

function DeleteTaskDB(task)
	if not task.Parent then
		error("DeleteTask: Cannot delete task that is a root task in Spore or which does not have any parent.",2)
	end
	local taskList
	taskList = task.Parent.SubTasks
	for i = 1,#taskList do
		if taskList[i] == task then
			for j = i, #taskList-1 do
				taskList[j] = taskList[j+1]
			end
			taskList[#taskList] = nil
			taskList.tasks = taskList.tasks - 1
			break
		end
	end
end

function sporeTitle(path)
	-- Find the name of the file
	local strVar
	local intVar1 = -1
	for intVar = #path,1,-1 do
		if string.sub(path, intVar, intVar) == "." then
	    	intVar1 = intVar
		end
		if string.sub(path, intVar, intVar) == "\\" or string.sub(path, intVar, intVar) == "/" then
	    	strVar = string.sub(path, intVar + 1, intVar1-1)
	    	break
		end
	end
	if not strVar then
		strVar = path
	end
	return strVar

end

-- Function to convert XML data from a single spore to internal data structure
-- Task structure
-- Task.
--	Planning
--	[0] = Task
-- 	SporeFile
--	Title
--	Modified
--	DBDATA
--	TaskID
--	Start
--	Fin
--	Private
--	Who
--	Access
--	Assignee
--	Status
--	Parent = Pointer to the Task to which this is a sub task
--	Priority
--	Due
--	Comments
--	Cat
--	SubCat
--	Tags
--	Schedules.
--		[0] = "Schedules"
--		Estimate.
--			[0] = "Estimate"
--			count
--			[i] = 
--		Commit.
--			[0] = "Commit"
--		Revs
--		Actual
--	SubTasks.
--		[0] = "SubTasks"
--		parent  = pointer to the array containing the list of tasks having the task whose SubTask this is 
--		tasks = count of number of subtasks
--		[i] = Task table like this one repeated for sub tasks

function XML2Data(SporeXML, SporeFile)
	-- tasks counts the number of tasks at the current level
	-- index 0 contains the name of this level to make it compatible with LuaXml
	local dataStruct = {Title = sporeTitle(SporeFile), SporeFile = SporeFile, tasks = 0, TaskID = Globals.ROOTKEY..SporeFile, [0] = "Task_Spore"}	-- to create the data structure
	if SporeXML[0]~="Task_Spore" then
		return nil
	end
	local currNode = SporeXML		-- currNode contains the current XML node being processed
	local hierInfo = {}
	hierInfo[currNode] = {count = 1}		-- hierInfo contains associated information with the currNode i.e. its Parent and count of the node being processed
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
				-- Each task has a Parent Attribute which points to a parent Task containing this task. For root tasks in the spore this is nil
				dataStruct[dataStruct.tasks].Parent = hierInfo[currNode].parentTask
				-- Extract all task information here
				local count = 1
				while(task[count]) do
					if task[count][0] == "Title" then
						dataStruct[dataStruct.tasks].Title = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Modified" then
						if task[count][1] == "YES" then
							dataStruct[dataStruct.tasks].Modified = true
						else
							dataStruct[dataStruct.tasks].Modified = false
						end
						necessary = necessary + 1
					elseif task[count][0] == "DB-Data" then
						dataStruct[dataStruct.tasks].DBDATA = {[0]="DB-Data",DBID = task[count][1][1], Updated = task[count][2][1]}
					elseif task[count][0] == "TaskID" then
						dataStruct[dataStruct.tasks].TaskID = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Start" then
						dataStruct[dataStruct.tasks].Start = task[count][1]
						necessary = necessary + 1
					elseif task[count][0] == "Fin" then
						dataStruct[dataStruct.tasks].Fin = task[count][1]
					elseif task[count][0] == "Private" then
						if task[count][1] == "Private" then
							dataStruct[dataStruct.tasks].Private = true
						else
							dataStruct[dataStruct.tasks].Private = false
						end
						necessary = necessary + 1
					elseif task[count][0] == "People" then
						for j = 1,#task[count] do
							if task[count][j][0] == "Who" then
								local WhoTable = {[0]="Who", count = #task[count][j]}
								-- Loop through all the items in the Who element
								for i = 1,#task[count][j] do
									WhoTable[i] = {ID = task[count][j][i][1][1], Status = task[count][j][i][2][1]}
								end
								necessary = necessary + 1
								dataStruct[dataStruct.tasks].Who = WhoTable
							elseif task[count][j][0] == "Locked" then
								local locked = {[0]="Access", count = #task[count][j]}
								-- Loop through all the items in the Locked element Access List
								for i = 1,#task[count][j] do
									locked[i] = {ID = task[count][j][i][1][1], Status = task[count][j][i][2][1]}
								end
								dataStruct[dataStruct.tasks].Access = locked
							elseif task[count][j][0] == "Assignee" then
								local assignee = {[0]="Assignee", count = #task[count][j]}
								-- Loop through all the items in the Assignee element
								for i = 1,#task[count][j] do
									assignee[i] = {ID = task[count][j][i][1]}
								end				
								dataStruct[dataStruct.tasks].Assignee = assignee					
							end		-- if task[count][j][0] == "Who" then ends here				
						end		-- for j = 1,#task[count] do ends here				
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
							tagTable[i] = task[count][i][1]
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
												if task[count][i][j][n][k][2] then
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
												end		-- if task[count][i][n][k][2] then ends
											end		-- for k = 1,#task[count][i][j] do ends
											estimate[j].Period = period
										end		-- if task[count][i][j][0] == "Hours" then ends
									end		-- for n = 1,#task[count][i][j] do ends
								end		-- for j = 1,#task[count][i] do ends
								schedule.Estimate = estimate
							elseif task[count][i][0] == "Commit" then
								local commit = {[0]="Commit"}
								commit.Comment = task[count][i][1][1][1]
								commit.Updated = task[count][i][1][2][1]
								local period = {[0] = "Period", count = #task[count][i][1][3]}
								-- Loop through all the day plans
								for k = 1,#task[count][i][1][3] do
									period[k] = {[0] = "DP", Date = task[count][i][1][3][k][1][1]}
									if task[count][i][1][3][k][2] then
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
									end		-- if task[count][i][n][k][2] then ends
								end		-- for k = 1,#task[count][i][j] do ends
								commit.Period = period
								schedule.Commit = {commit,[0]="Commit", count = 1}
							elseif task[count][i][0] == "Revs" then
								local revs = {[0]="Revs", count = #task[count][i]}
								-- Loop through all the Revisions
								for j = 1,#task[count][i] do
									revs[j] = {[0]="Revs"}
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
												if task[count][i][j][n][k][2] then
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
												end		-- if task[count][i][n][k][2] then ends
											end		-- for k = 1,#task[count][i][j] do ends
											revs[j].Period = period
										end		-- if task[count][i][j][0] == "Hours" then ends
									end		-- for n = 1,#task[count][i][j] do ends
								end		-- for j = 1,#task[count][i] do ends
								schedule.Revs = revs
							elseif task[count][i][0] == "Actual" then
								local actual = {[0]= "Actual", count = 1}
								local period = {[0] = "Period", count = #task[count][i]-1} 
								-- Loop through all the work done elements
								for j = 2,period.count+1 do
									period[j] = {[0]="WD", Date = task[count][i][j][1][1]}
									for k = 2,#task[count][i][j] do
										if task[count][i][j][k][0] == "Hours" then
											period[j].Hours = task[count][i][j][k][1]
										elseif task[count][i][j][k][0] == "Comment" then
											period[j].Comment = task[count][i][j][k][1]
										end
									end
								end
								actual[1] = {Period = period,[0]="Actual", Updated = task[count][i][1][1]}
								schedule.Actual = actual
							end							
						end
						dataStruct[dataStruct.tasks].Schedules = schedule
					elseif task[count][0] == "SubTasks" then
						hierInfo[task[count]] = {count = 1, parent = currNode,parentTask = dataStruct[dataStruct.tasks]}
						currNode = task[count]
						dataStruct[dataStruct.tasks].SubTasks = {parent = dataStruct, tasks = 0, [0]="SubTasks"}
						dataStruct = dataStruct[dataStruct.tasks].SubTasks
					end
					count = count + 1
				end		-- while(task[count]) do ends
				if necessary < 7 then
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
		end		-- if not(currNode[hierInfo[currNode].count]) then ends
	end		-- while(currNode[hierInfo[level].count]) ends here
	while dataStruct.parent do
		dataStruct = dataStruct.parent
	end
	return dataStruct
end		-- function XML2Data(SporeXML) ends here
