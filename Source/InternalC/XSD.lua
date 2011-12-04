
--module(...)

require('LuaXml')

function readXSD(fileName)
	local xsdFile = xml.load(fileName)
	local elements = {}			-- Blank table to store the element hierarchy
	local hier = {}				-- Table to traverse the hierarchy without recursion
	local hierChildNo = {}		-- To store the child number from where to resume the traversal at the particular level
	local elemLvlControl = {}	-- Array to store flags whether the elements hierarchy table needs to change level or not with hier
	local customTypes = {}		-- Blank table to store custom types defined in the XSD

-- ######################################################################
-- XSD STANDARD NOTE
-- ######################################################################
-- XSD allows multiple elements tobe defined in the  XSD file which may
-- be used as the root element but any XML document can have just 1 root
-- element
-- CODE ASSUMPTION 1:
-- Here the code assumes that the XSD file only has 1 element defined in the xsdFile
-- that can act as the root element
-- CODE ASSUMPTION 2:
-- Any included files with defined types will not be read
-- ######################################################################
	-- Find the initial root element
	-- Also collect all the customTypes at this level
	for i=1,#xsdFile do
		if string.upper(xsdFile[i][0]) == "XS:ELEMENT" then
			-- This is the root element
			hier[1] = xsdFile[i]
			hierChildNo[1] = 1
		elseif string.upper(xsdFile[i][0]) == "XS:COMPLEXTYPE" then
			if xsdFile[i].name then
				customTypes[#customTypes + 1] = xsdFile[i]
			end
		elseif string.upper(xsdFile[i][0]) == "XS:SIMPLETYPE" then
			if xsdFile[i].name then
				customTypes[#customTypes + 1] = xsdFile[i]
			end
		elseif string.upper(xsdFile[i][0]) == "XS:INCLUDE" then
			-- Not handling include files right now

		end
	end							-- for i=1,#xsdFile do ends here

	-- Now start the hierarchy traversal with hier[1] node
	local i = 1
	elements[0] = hier[i].name	-- store the name of the element at index 0
	local jump = nil
	while(i>0) do
		for j = hierChildNo[i],#hier[i] do
			if string.upper(hier[i][j][0]) == "XS:ELEMENT" then
				-- This is a child element
				hier[i+1] = hier[i][j]
				hierChildNo[i] = j + 1		-- When we return to this level start with the next child
				hierChildNo[i+1] = 1		-- Start with the 1st child of this sub element
				elemLvlControl[i+1] = true
				i = i + 1
				-- Go down a level in elements
				elements[#elements + 1] = {}
				elements[#elements][-1] = elements
				elements = elements[#elements]
				elements[0] = hier[i].name
				-- Check if this type is in the customTypes list
				for k=1,#customTypes do
					if customTypes[k].name == hier[i].type then
						hier[i] = customTypes[k]
						jump = true
						break
					end
				end
				jump = true
				break
			elseif string.upper(hier[i][j][0]) == "XS:COMPLEXTYPE" or
				    string.upper(hier[i][j][0]) == "XS:SEQUENCE" or
				    string.upper(hier[i][j][0]) == "XS:CHOICE" or
				    string.upper(hier[i][j][0]) == "XS:ALL" then
				if hier[i][j].name then
					customTypes[#customTypes + 1] = hier[i][j]
				else
					-- Go into this complex type to find child elements
					hier[i+1] = hier[i][j]
					hierChildNo[i] = j + 1		-- When we return to this level start with the next child
					hierChildNo[i+1] = 1		-- Start with the 1st child of this sub element
					i = i + 1
					jump = true
					break
				end
			elseif string.upper(hier[i][j][0]) == "XS:SIMPLETYPE" then
				if hier[i][j].name then
					customTypes[#customTypes + 1] = hier[i][j]
				end
			elseif string.upper(hier[i][0]) == "XS:INCLUDE" then
				-- Not handling include files right now

			end
		end						-- for j = hierChildNo[i],#hier[i] do ends
		if jump then
			-- This is a jump to a lower hierarchy
			jump = nil			-- Reset the jump flag
		else
			-- Go up a level in elements if needed
			if elemLvlControl[i] then
				elements = elements[-1]
			end
			-- Go up a level in the hierarchy since all children in this hierarchy are done
			i = i - 1
		end
	end
	return true, elements
end

status,e = readXSD('Task_Spore.xsd')
