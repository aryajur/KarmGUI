-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Validator functions for various data structures for Karm
-- Author:      Milind Gupta
-- Created:     6/28/2012
-- Requirements:Should be launched from Karm
-----------------------------------------------------------------------------

function checkTask(task)
end

function validateSpore(Spore)
	if not Spore then
		return nil
	elseif type(Spore) ~= "table" then
		return nil
	elseif Spore[0] ~= "Task_Spore" then
		return nil
	end
	return true
end

