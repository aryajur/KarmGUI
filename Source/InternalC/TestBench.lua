
--[[
---- Convert Boolean String to table test bench
require('DataHandler')
str = "A1 and A2 OR A3 and NOT A4"

a = convertBoolStr2Tab(str)

print(a)
]]

---- Table to String test bench
require('DataHandler')
tt = {count = 0, newTab = {test = "Hello World",[1] = true}}
myTab = {
			[1] = "Hello",
			[2] = 1,
			[3] = {	Test = 1},
			[4] = true,
			str1 = "World",
			str2 = 2,
			str3 = { Test1 = 2},
			str4 = true,
			[tt] = "Great",
			[tt] = 3,
			[tt] = {Test2 = 3},
			[tt] = true
		}
		
a = tableToString2(myTab)
print(a)
