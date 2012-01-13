-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm Initialization
-- Author:      Milind Gupta
-- Created:     1/13/2012
-----------------------------------------------------------------------------

module(...,package.seeall)

-- Include the LuaXml package to provide XML parsing
require('LuaXml')

configFile = "KarmConfig.lua"

-- load the configuration file
dofile("KarmConfig.lua")
-- Load all the XML spores
count = 1
-- print(Spores[count])
if Spores then
	SporeXML = {}
	while Spores[count] do
		SporeXML[1] = xml.load(Spores[count])
		count = count + 1
	end
end
-- print("count = ", count)

print(Spores)


