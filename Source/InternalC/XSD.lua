

module(...,package.seeall)

require('LuaXml')


local privates = {}		-- table to store all private data of instantiated objects

function xsdFile(self)
	return privates[self].xsdFile
end

function xmlFiles(self)
	return privates[self].xmlFiles
end

function xsdStruct(self)
	return privates[self].xsdStruct
end

--****f* XSD/readXSD
-- FUNCTION
-- Function to read an XSD file and create the tree XML for the elements defined in the xsdFile
-- The Choice and all content organizers are ignored in the collection since all the possible elements
-- need to be accumulated which is what this function does.

-- KNOWN ISSUES
-- o XSD allows multiple elements tobe defined in the  XSD file which may be used as the root element but any XML document can have just 1 root element
-- ASSUMPTION 1:
-- Here the code assumes that the XSD file only has 1 element defined in the xsdFile
-- that can act as the root element
-- ASSUMPTION 2:
-- Any included files with defined types will not be read

-- RETURNS
-- status - status code for the function
-- XML table representing the elements allowed in the XSD

-- SOURCE
local function readXSD(fileName)
--@@END@@
	local xsdFile = xml.load(fileName)
	local elements = {}			-- Blank table to store the element hierarchy
	local hier = {}				-- Table to traverse the hierarchy without recursion
	local hierChildNo = {}		-- To store the child number from where to resume the traversal at the particular level
	local elemLvlControl = {}	-- Array to store flags whether the elements hierarchy table needs to change level or not with hier, second flag for customTypeHier
	local customTypes = {}		-- Blank table to store custom types defined in the XSD
	local customTypeHier = {}	-- To store the custom type hierarchy to detect recursive XSDs

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
	elemLvlControl[i] = {nil,nil}
	local jump = nil
	while(i>0) do
		for j = hierChildNo[i],#hier[i] do
			if string.upper(hier[i][j][0]) == "XS:ELEMENT" then
				-- This is a child element
				hier[i+1] = hier[i][j]
				hierChildNo[i] = j + 1		-- When we return to this level start with the next child
				hierChildNo[i+1] = 1		-- Start with the 1st child of this sub element
				elemLvlControl[i+1] = {true,nil}
				i = i + 1
				-- Go down a level in elements keeping the elements structure compliant with LuaXML code
				elements[#elements + 1] = {}
				elements[#elements][-1] = elements
				elements = elements[#elements]
				elements[0] = hier[i].name
				-- Check if this type is in the customTypes list
				for k=1,#customTypes do
					if customTypes[k].name == hier[i].type then
						-- Check if this is a recursive node
						local l = #customTypeHier
						while l>=1 do
							if customTypeHier[l][1] == customTypes[k].name then
								-- This is a recursive customType so we need to stop here
								jump = true
								break
							end
							l = l - 1
						end -- for #customTypeHier ends here
						if jump then
							-- This is a recursive customType so we need to stop here
							-- Mark this element as recursive
							elements.recurseElem = customTypeHier[l][2]
							jump = false
							elemLvlControl[i] = nil
							elements = elements[-1]
							i = i - 1
							break
						else
							-- Now we are going into a custom type so add it to the custom type hierarchy
							-- Find the XPATH of the current element
							pathTop = elements
							path = pathTop[0]
							while pathTop[-1] do
								pathTop = pathTop[-1]
								path = pathTop[0] .. '\\' .. path
							end
							customTypeHier[#customTypeHier + 1] = {customTypes[k].name,path}
							elemLvlControl[i][2] = true
							hier[i] = customTypes[k]
							jump = true
							break
						end
					end
				end
				jump = true
				break
			elseif string.upper(hier[i][j][0]) == "XS:COMPLEXTYPE" or
				    string.upper(hier[i][j][0]) == "XS:SEQUENCE" or
				    string.upper(hier[i][j][0]) == "XS:CHOICE" or
				    string.upper(hier[i][j][0]) == "XS:ALL" then
				if hier[i][j].name then
					-- This is a custom type so add it to the custom type library
					customTypes[#customTypes + 1] = hier[i][j]
				else
					-- Go into this complex type to find child elements
					hier[i+1] = hier[i][j]
					hierChildNo[i] = j + 1		-- When we return to this level start with the next child
					hierChildNo[i+1] = 1		-- Start with the 1st child of this sub element
					elemLvlControl[i+1] = {nil,nil}
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
			if elemLvlControl[i][1] then
				if elemLvlControl[i][2] then
					customTypeHier[#customTypeHier] = nil
				end
				elemLvlControl[i] = nil
				elements = elements[-1]
			end
			-- Go up a level in the hierarchy since all children in this hierarchy are done
			i = i - 1
		end
	end				-- while(i>0) do ends here
	setmetatable(elements,getmetatable(xsdFile))
	return true, elements
end

--****f* XSD.new
-- FUNCTION
-- Function to create a new XSD object with an associated XSD file and xmlfiles
function new(self,xsdFile,xmlFiles)
	-- Do error checking for xsdFile and xmlFiles
	print(xsdFile)
	print(xmlFiles)
	local status
	local xsdStruct
	status, xsdStruct = readXSD(xsdFile)

	local newObj = {}
	setmetatable(newObj,self)
	self.__index = self
	privates[newObj] = {xsdFile = xsdFile, xmlFiles = xmlFiles, xsdStruct = xsdStruct}
	return newObj
end
