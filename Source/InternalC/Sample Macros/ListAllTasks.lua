-- Macros always run in global environment. 
-- Always be careful not to pollute it the global environment

-- Macro to list all tasks of the 1st loaded spore
local Spore
-- Get the first loaded spore from the Karm.SporeData table
for k,v in pairs(Karm.SporeData) do
	if k ~= 0 then
		-- This is the 1st spore
		Spore = v
		break
	end
end
local str = "" 
str = str..Spore[1].Title.."\n"
local nextTask = Karm.TaskObject.NextInSequence(Spore[1])
while nextTask do
	str = str..nextTask.Title.."\n"
	nextTask = Karm.TaskObject.NextInSequence(nextTask)
end
print(str)
