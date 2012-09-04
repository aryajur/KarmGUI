__MANY2ONEFILES={}
		function requireLuaString(str) 
			if not package.loaded[str] then 
				package.loaded[str] = true
				local res = loadstring(__MANY2ONEFILES[str])
				res = res(str)
				if res ~= nil then
					package.loaded[str] = res
				end
			end 
			return package.loaded[str] 
		end
		__MANY2ONEFILES['CustomWidgets']="-----------------------------------------------------------------------------\
-- Application: Various\
-- Purpose:     Custom widgets using wxwidgets\
-- Author:      Milind Gupta\
-- Created:     2/09/2012\
-- Requirements:WxWidgets should be present already in the lua space\
-----------------------------------------------------------------------------\
local prin\
if Karm.Globals.__DEBUG then\
	prin = print\
end\
local error = error\
local print = prin \
local wx = wx\
local bit = bit\
local type = type\
local string = string\
local tostring = tostring\
local tonumber = tonumber\
local pairs = pairs\
local setfenv = setfenv\
local compareDateRanges = Karm.Utility.compareDateRanges\
local combineDateRanges = Karm.Utility.combineDateRanges\
\
\
local NewID = Karm.NewID    -- This is a function to generate a unique wxID for the application this module is used in\
\
local modname = ...\
----------------------------------------------------------\
--module(modname)\
-- NOT USING THE module KEYWORD SINCE IT DOES THIS ALSO _G[modname] = M\
local M = {}\
package.loaded[modname] = M\
setfenv(1,M)\
----------------------------------------------------------\
\
if not NewID then\
	local ID_IDCOUNTER = wx.wxID_HIGHEST + 1\
	function NewID()\
	    ID_IDCOUNTER = ID_IDCOUNTER + 1\
	    return ID_IDCOUNTER\
	end\
end\
	\
-- Object to generate and manage a check list \
do\
	local objMap = {}		-- private static variable\
	local imageList\
	\
	local getSelectedItems = function(o)\
		local selItems = {}\
		local itemNum = -1\
\
		while o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED) ~= -1 do\
			itemNum = o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
			local str\
			local item = wx.wxListItem()\
			item:SetId(itemNum)\
			item:SetMask(wx.wxLIST_MASK_IMAGE)\
			o.List:GetItem(item)\
			if item:GetImage() == 0 then\
				-- Item checked\
				str = o.checkedText\
			else\
				-- Item Unchecked\
				str = o.uncheckedText\
			end\
			item:SetId(itemNum)\
			item:SetColumn(1)\
			item:SetMask(wx.wxLIST_MASK_TEXT)\
			o.List:GetItem(item)\
			-- str = item:GetText()..\",\"..str\
			selItems[#selItems + 1] = {itemText=item:GetText(),checked=str}\
		end\
		return selItems\
	end\
		\
	local getAllItems = function(o)\
		local selItems = {}\
		local itemNum = -1\
\
		while o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL) ~= -1 do\
			itemNum = o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL)\
			local str\
			local item = wx.wxListItem()\
			item:SetId(itemNum)\
			item:SetMask(wx.wxLIST_MASK_IMAGE)\
			o.List:GetItem(item)\
			if item:GetImage() == 0 then\
				-- Item checked\
				str = o.checkedText\
			else\
				-- Item Unchecked\
				str = o.uncheckedText\
			end\
			item:SetId(itemNum)\
			item:SetColumn(1)\
			item:SetMask(wx.wxLIST_MASK_TEXT)\
			o.List:GetItem(item)\
			-- str = item:GetText()..\",\"..str\
			selItems[#selItems + 1] = {itemText=item:GetText(),checked=str}\
		end\
		return selItems\
	end\
\
	local InsertItem = function(o,Item,checked)\
		local ListBox = o.List\
		-- Check if the Item exists in the list control\
		local itemNum = -1\
		-- print(ListBox:GetNextItem(itemNum))\
		while ListBox:GetNextItem(itemNum) ~= -1 do\
			local prevItemNum = itemNum\
			itemNum = ListBox:GetNextItem(itemNum)\
			local obj = wx.wxListItem()\
			obj:SetId(itemNum)\
			obj:SetColumn(1)\
			obj:SetMask(wx.wxLIST_MASK_TEXT)\
			ListBox:GetItem(obj)\
			local itemText = obj:GetText()\
			if itemText == Item then\
				-- Get checked status and update\
				if checked then\
					ListBox:SetItemImage(itemNum,0)\
				else\
					ListBox:SetItemImage(itemNum,1)\
				end				\
				return true\
			end\
			if itemText > Item then\
				itemNum = prevItemNum\
				break\
			end \
		end\
		-- itemNum contains the item after which to place item\
		if itemNum == -1 then\
			itemNum = 0\
		else \
			itemNum = itemNum + 1\
		end\
		local newItem = wx.wxListItem()\
		local img\
		newItem:SetId(itemNum)\
		--newItem:SetText(Item)\
		if checked then\
			newItem:SetImage(0)\
		else\
			newItem:SetImage(1)\
		end				\
		--newItem:SetTextColour(wx.wxColour(wx.wxBLACK))\
		ListBox:InsertItem(newItem)\
		ListBox:SetItem(itemNum,1,Item)\
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)		\
		ListBox:SetColumnWidth(1,wx.wxLIST_AUTOSIZE)		\
		return true\
	end\
\
	local ResetCtrl = function(o)\
		o.List:DeleteAllItems()\
		o.List:SetImageList(imageList,wx.wxIMAGE_LIST_SMALL)\
	end\
\
	local RightClick = function(event)\
		setfenv(1,package.loaded[modname])\
		local o = objMap[event:GetId()]\
		--o.List:SetImageList(o.mageList,wx.wxIMAGE_LIST_SMALL)\
		local item = wx.wxListItem()\
		local itemNum = event:GetIndex()\
		item:SetId(itemNum)\
		item:SetMask(wx.wxLIST_MASK_IMAGE)\
		o.List:GetItem(item)\
		if item:GetImage() == 0 then\
			--item:SetImage(1)\
			o.List:SetItemColumnImage(item:GetId(),0,1)\
		else\
			--item:SetImage(0)\
			o.List:SetItemColumnImage(item:GetId(),0,0)\
		end\
		event:Skip()\
	end\
\
	CheckListCtrl = function(parent,noneSelection,checkedText,uncheckedText,singleSelection)\
		if not parent then\
			return nil\
		end\
		local o = {ResetCtrl = ResetCtrl, InsertItem = InsertItem, getSelectedItems = getSelectedItems, getAllItems = getAllItems}	-- new object\
		o.Sizer = wx.wxBoxSizer(wx.wxVERTICAL)\
		o.checkedText = checkedText or \"YES\"\
		o.uncheckedText = uncheckedText or \"NO\"\
		local ID\
		ID = NewID()	\
		if singleSelection then	\
			o.List = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_SINGLE_SEL+wx.wxLC_NO_HEADER)\
		else\
			o.List = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\
		end\
		objMap[ID] = o\
		-- Create the imagelist and add check and uncheck icons\
		imageList = wx.wxImageList(16,16,true,0)\
		local icon = wx.wxIcon()\
		icon:LoadFile(\"images/checked.xpm\",wx.wxBITMAP_TYPE_XPM)\
		imageList:Add(icon)\
		icon:LoadFile(\"images/unchecked.xpm\",wx.wxBITMAP_TYPE_XPM)\
		imageList:Add(icon)\
		o.List:SetImageList(imageList,wx.wxIMAGE_LIST_SMALL)\
		-- Add Items\
		o.List:InsertColumn(0,\"Check\")\
		o.List:InsertColumn(1,\"Options\")\
		o.Sizer:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		o.List:Connect(wx.wxEVT_COMMAND_LIST_ITEM_RIGHT_CLICK, RightClick)\
		return o\
	end\
	\
end	-- CheckListCtrl ends\
\
\
-- Two List boxes and 2 buttons in between class\
do\
	local objMap = {}	-- Private Static variable\
\
	-- This is exposed to the module since it is a generic function for a listBox\
	InsertItem = function(ListBox,Item)\
		-- Check if the Item exists in the list control\
		local itemNum = -1\
		while ListBox:GetNextItem(itemNum) ~= -1 do\
			local prevItemNum = itemNum\
			itemNum = ListBox:GetNextItem(itemNum)\
			local itemText = ListBox:GetItemText(itemNum)\
			if itemText == Item then\
				return true\
			end\
			if itemText > Item then\
				itemNum = prevItemNum\
				break\
			end \
		end\
		-- itemNum contains the item after which to place item\
		if itemNum == -1 then\
			itemNum = 0\
		else \
			itemNum = itemNum + 1\
		end\
		local newItem = wx.wxListItem()\
		newItem:SetId(itemNum)\
		newItem:SetText(Item)\
		newItem:SetTextColour(wx.wxColour(wx.wxBLACK))\
		ListBox:InsertItem(newItem)\
		ListBox:SetItem(itemNum,0,Item)\
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)\
		return true\
	end\
	\
	local getSelectedItems = function(o)\
		-- Function to return all the selected items in an array\
		-- if the index 0 of the array is true then the none selection checkbox is checked\
		local selItems = {}\
		local SelList = o.SelList\
		local itemNum = -1\
		while SelList:GetNextItem(itemNum) ~= -1 do\
			itemNum = SelList:GetNextItem(itemNum)\
			local itemText = SelList:GetItemText(itemNum)\
			selItems[#selItems + 1] = itemText\
		end\
		-- Finally Check if none selection box exists\
		if o.CheckBox and o.CheckBox:GetValue() then\
			selItems[0] = \"true\"\
		end\
		return selItems\
	end\
	\
	local AddPress = function(event)\
		setfenv(1,package.loaded[modname])\
		-- Transfer all selected items from List to SelList\
		local item\
		local o = objMap[event:GetId()]\
		local list = o.List\
		local selList = o.SelList\
		item = list:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
		local selItems = {}\
		while item ~= -1 do\
			local itemText = list:GetItemText(item)\
			InsertItem(selList,itemText)			\
			selItems[#selItems + 1] = item	\
			item = list:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
		end\
		for i=#selItems,1,-1 do\
			list:DeleteItem(selItems[i])\
		end\
		if o.TextBox and o.TextBox:GetValue() ~= \"\" then\
			InsertItem(selList,o.TextBox:GetValue())\
			o.TextBox:SetValue(\"\")\
		end\
	end\
	\
	local ResetCtrl = function(o)\
		o.SelList:DeleteAllItems()\
		o.List:DeleteAllItems()\
		if o.CheckBox then\
			o.CheckBox:SetValue(false)\
		end\
	end\
	\
	local RemovePress = function(event)\
		setfenv(1,package.loaded[modname])\
		-- Transfer all selected items from SelList to List\
		local item\
		local o = objMap[event:GetId()]\
		local list = o.List\
		local selList = o.SelList\
		item = selList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
		local selItems = {}\
		while item ~= -1 do\
			local itemText = selList:GetItemText(item)\
			InsertItem(list,itemText)			\
			selItems[#selItems + 1] = item	\
			item = selList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
		end\
		for i=#selItems,1,-1 do\
			selList:DeleteItem(selItems[i])\
		end\
	end\
	\
	local AddListData = function(o,items)\
		if items then\
			for i = 1,#items do\
				InsertItem(o.List,items[i])\
			end\
		end\
	end\
	\
	local AddSelListData = function(o,items)\
		for i = 1,#items do\
			local item = o.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL)\
			while item ~= -1 do\
				local itemText = o.List:GetItemText(item)\
				if itemText == items[i] then\
					o.List:DeleteItem(item)\
					break\
				end		\
				item = o.List:GetNextItem(item,wx.wxLIST_NEXT_ALL)	\
			end\
			InsertItem(o.SelList,items[i])\
		end	\
	end\
	\
	MultiSelectCtrl = function(parent, LItems, RItems, noneSelection, textEntry)\
		if not parent then\
			return nil\
		end\
		LItems = LItems or {}\
		RItems = RItems or {} \
		local o = {AddSelListData=AddSelListData, AddListData=AddListData, ResetCtrl=ResetCtrl, getSelectedItems = getSelectedItems}	-- new object\
		-- Create the GUI elements here\
		o.Sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
			local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\
			o.List = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\
			-- Add Items\
			--local col = wx.wxListItem()\
			--col:SetId(0)\
			o.List:InsertColumn(0,\"Options\")\
			o:AddListData(LItems)\
			sizer1:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			local ID\
			if textEntry then\
				o.TextBox = wx.wxTextCtrl(parent, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize)\
				sizer1:Add(o.TextBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			end\
			if noneSelection then\
				ID = NewID()\
				local str\
				if type(noneSelection) ~= \"string\" then\
					str = \"None Also Passes\"\
				else\
					str = noneSelection\
				end\
				o.CheckBox = wx.wxCheckBox(parent, ID, str, wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				objMap[ID] = o \
				sizer1:Add(o.CheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			end\
			o.Sizer:Add(sizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			local ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
				ID = NewID()\
				o.AddButton = wx.wxButton(parent, ID, \">\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				ButtonSizer:Add(o.AddButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				objMap[ID] = o \
				ID = NewID()\
				o.RemoveButton = wx.wxButton(parent, ID, \"<\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				ButtonSizer:Add(o.RemoveButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				objMap[ID] = o\
			o.Sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			o.SelList = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\
			-- Add Items\
			--col = wx.wxListItem()\
			--col:SetId(0)\
			o.SelList:InsertColumn(0,\"Selections\")\
			o:AddListData(RItems)\
			o.Sizer:Add(o.SelList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		-- Connect the buttons to the event handlers\
		o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,AddPress)\
		o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,RemovePress)\
		return o\
	end\
end\
--  MultiSelectCtrl ends\
\
-- Boolean Tree and Boolean buttons\
do\
\
	local objMap = {}	-- Private Static variable\
	\
	-- Function to convert a boolean string to a Table\
	-- Table elements '#AND#', '#OR#', '#NOT()#', '#NOT(AND)#' and '#NOT(OR)#' are reserved and their children are the ones \
	-- on which this operation is performed.\
	-- The table consist of:\
	-- 1. Item - contains the item name\
	-- 2. Parent - contains the parent table\
	-- 3. Children - contains a sequence of tables starting from index = 1 similar to the root table\
	local function convertBoolStr2Tab(str)\
		local boolTab = {Item=\"\",Parent=nil,Children = {},currChild=nil}\
		local strLevel = {}\
		local subMap = {}\
		\
		local getUniqueSubst = function(str,subMap)\
			if not subMap.latest then\
				subMap.latest = 1\
			else \
				subMap.latest = subMap.latest + 1\
			end\
			-- Generate prospective nique string\
			local uStr = \"A\"..tostring(subMap.latest)\
			local done = false\
			while not done do\
				-- Check if this unique string exists in str\
				while string.find(str,\"[%(%s]\"..uStr..\"[%)%s]\") or \
				  string.find(string.sub(str,1,string.len(uStr) + 1),uStr..\"[%)%s]\") or \
				  string.find(string.sub(str,-(string.len(uStr) + 1),-1),\"[%(%s]\"..uStr) do\
					subMap.latest = subMap.latest + 1\
					uStr = \"A\"..tostring(subMap.latest)\
				end\
				done = true\
				-- Check if the str exists in subMap mappings already replaced\
				for k,v in pairs(subMap) do\
					if k ~= \"latest\" then\
						while string.find(v,\"[%(%s]\"..uStr..\"[%)%s]\") or \
						  string.find(string.sub(v,1,string.len(uStr) + 1),uStr..\"[%)%s]\") or \
						  string.find(string.sub(v,-(string.len(uStr) + 1),-1),\"[%(%s]\"..uStr) do\
							done = false\
							subMap.latest = subMap.latest + 1\
							uStr = \"A\"..tostring(subMap.latest)\
						end\
						if done==false then \
							break \
						end\
					end\
				end		-- for k,v in pairs(subMap) do ends\
			end		-- while not done do ends\
			return uStr\
		end		-- function getUniqueSubst(str,subMap) ends\
		\
		local bracketReplace = function(str,subMap)\
			-- Function to replace brackets with substitutions and fill up the subMap (substitution map)\
			-- Make sure the brackets are consistent\
			local _,stBrack = string.gsub(str,\"%(\",\"t\")\
			local _,enBrack = string.gsub(str,\"%)\",\"t\")\
			if stBrack ~= enBrack then\
				error(\"String does not have consistent opening and closing brackets\",2)\
			end\
			local brack = string.find(str,\"%(\")\
			while brack do\
				local init = brack + 1\
				local fin\
				-- find the ending bracket for this one\
				local count = 0	-- to track additional bracket openings\
				for i = init,str:len() do\
					if string.sub(str,i,i) == \"(\" then\
						count = count + 1\
					elseif string.sub(str,i,i) == \")\" then\
						if count == 0 then\
							-- this is the matching bracket\
							fin = i-1\
							break\
						else\
							count = count - 1\
						end\
					end\
				end		-- for i = init,str:len() do ends\
				if count ~= 0 then\
					error(\"String does not have consistent opening and closing brackets\",2)\
				end\
				local uStr = getUniqueSubst(str,subMap)\
				local pre = \"\"\
				local post = \"\"\
				if init > 2 then\
					pre = string.sub(str,1,init-2)\
				end\
				if fin < str:len() - 2 then\
					post = string.sub(str,fin + 2,str:len())\
				end\
				subMap[uStr] = string.sub(str,init,fin)\
				str = pre..\" \"..uStr..\" \"..post\
				-- Now find the next\
				brack = string.find(str,\"%(\")\
			end		-- while brack do ends\
			str = string.gsub(str,\"%s+\",\" \")		-- Remove duplicate spaces\
			str = string.match(str,\"^%s*(.-)%s*$\")\
			return str\
		end		-- function(str,subMap) ends\
		\
		local OperSubst = function(str, subMap,op)\
			-- Function to make the str a simple OR expression\
			op = string.lower(string.match(op,\"%s*([%w%W]+)%s*\"))\
			if not(string.find(str,\" \"..op..\" \") or string.find(str,\" \"..string.upper(op)..\" \")) then\
				return str\
			end\
			str = string.gsub(str,\" \"..string.upper(op)..\" \", \" \"..op..\" \")\
			-- Starting chunk\
			local strt,stp,subStr = string.find(str,\"(.-) \"..op..\" \")\
			local uStr = getUniqueSubst(str,subMap)\
			local newStr = {count = 0} \
			newStr.count = newStr.count + 1\
			newStr[newStr.count] = uStr\
			subMap[uStr] = subStr\
			-- Middle chunks\
			strt,stp,subStr = string.find(str,\" \"..op..\" (.-) \"..op..\" \",stp-op:len()-1)\
			while strt do\
				uStr = getUniqueSubst(str,subMap)\
				newStr.count = newStr.count + 1\
				newStr[newStr.count] = uStr\
				subMap[uStr] = subStr			\
				strt,stp,subStr = string.find(str,\" \"..op..\" (.-) \"..op..\" \",stp-op:len()-1)	\
			end\
			-- Last Chunk\
			strt,stp,subStr = string.find(str,\"^.+ \"..op..\" (.-)$\")\
			uStr = getUniqueSubst(str,subMap)\
			newStr.count = newStr.count + 1\
			newStr[newStr.count] = uStr\
			subMap[uStr] = subStr\
			return newStr\
		end		-- local function ORsubst(str) ends\
		\
		-- First replace all quoted strings in the string with substitutions\
		local strSubMap = {}\
		local _,numQuotes = string.gsub(str,\"%'\",\"t\")\
		if numQuotes%2 ~= 0 then\
			error(\"String does not have consistent opening and closing quotes \\\"'\\\"\",2)\
		end\
		local init,fin = string.find(str,\"'.-'\")\
		while init do\
			local uStr = getUniqueSubst(str,subMap)\
			local pre = \"\"\
			local post = \"\"\
			if init > 1 then\
				pre = string.sub(str,1,init-1)\
			end\
			if fin < str:len() then\
				post = string.sub(str,fin + 1,str:len())\
			end\
			strSubMap[uStr] = str:sub(init,fin)\
			str = pre..\" \"..uStr..\" \"..post\
			-- Now find the next\
			init,fin = string.find(str,\"'.-'\")\
		end		-- while brack do ends\
		strLevel[boolTab] = str\
		-- Start recursive loop here\
		local currTab = boolTab\
		while currTab do\
			-- Remove all brackets\
			strLevel[currTab] = string.gsub(strLevel[currTab],\"%s+\",\" \")\
			strLevel[currTab] = bracketReplace(strLevel[currTab],subMap)\
			-- Check what type of element this is\
			if not(string.find(strLevel[currTab],\" or \") or string.find(strLevel[currTab],\" OR \") \
			  or string.find(strLevel[currTab],\" and \") or string.find(strLevel[currTab],\" AND \") \
			  or string.find(strLevel[currTab],\" not \") or string.find(strLevel[currTab],\" NOT \")\
			  or string.upper(string.sub(strLevel[currTab],1,4)) == \"NOT \"\
			  or subMap[strLevel[currTab]]) then\
				-- This is a simple element\
				if currTab.Item == \"#NOT()#\" then\
					currTab.Children[1] = {Item = strLevel[currTab],Parent=currTab}\
				else\
					currTab.Item = strLevel[currTab]\
					currTab.Children = nil\
				end\
				-- Return one level up\
				currTab = currTab.Parent\
				while currTab do\
					if currTab.currChild < #currTab.Children then\
						currTab.currChild = currTab.currChild + 1\
						currTab = currTab.Children[currTab.currChild]\
						break\
					else\
						currTab.currChild = nil\
						currTab = currTab.Parent\
					end\
				end\
			elseif not(string.find(strLevel[currTab],\" or \") or string.find(strLevel[currTab],\" OR \") \
			  or string.find(strLevel[currTab],\" and \") or string.find(strLevel[currTab],\" AND \") \
			  or string.find(strLevel[currTab],\" not \") or string.find(strLevel[currTab],\" NOT \")\
			  or string.upper(string.sub(strLevel[currTab],1,4)) == \"NOT \")\
			  and subMap[strLevel[currTab]] then\
				-- This is a substitution as a whole\
				local temp = strLevel[currTab] \
				strLevel[currTab] = subMap[temp]\
				subMap[temp] = nil\
			else\
				-- This is a normal expression\
				if string.find(strLevel[currTab],\" or \") or string.find(strLevel[currTab],\" OR \") then\
					-- The expression has OR operators\
					-- Transform to a simple OR expression\
					local simpStr = OperSubst(strLevel[currTab],subMap,\"OR\")\
					if currTab.Item == \"#NOT()#\" then\
						currTab.Item = \"#NOT(OR)#\"\
					else\
						currTab.Item = \"#OR#\"\
					end\
					-- Now allchildren need to be added and we must evaluate each child\
					for i = 1,#simpStr do\
						currTab.Children[#currTab.Children + 1] = {Item=\"\", Parent = currTab,Children={},currChild=nil}\
						strLevel[currTab.Children[#currTab.Children]] = simpStr[i]\
					end \
					currTab.currChild = 1\
					currTab = currTab.Children[1]\
				elseif string.find(strLevel[currTab],\" and \") or string.find(strLevel[currTab],\" AND \") then\
					-- The expression does not have OR operators but has AND operators\
					-- Transform to a simple AND expression\
					local simpStr = OperSubst(strLevel[currTab],subMap,\"AND\")\
					if currTab.Item == \"#NOT()#\" then\
						currTab.Item = \"#NOT(AND)#\"\
					else\
						currTab.Item = \"#AND#\"\
					end\
					-- Now allchildren need to be added and we must evaluate each child\
					for i = 1,#simpStr do\
						currTab.Children[#currTab.Children + 1] = {Item=\"\", Parent = currTab,Children={},currChild=nil}\
						strLevel[currTab.Children[#currTab.Children]] = simpStr[i]\
					end \
					currTab.currChild = 1\
					currTab = currTab.Children[1]\
				else\
					-- This is a NOT element\
					strLevel[currTab] = string.gsub(strLevel[currTab],\"NOT\", \"not\")\
					local elem = string.match(strLevel[currTab],\"%s*not%s+([%w%W]+)%s*\")\
					currTab.Item = \"#NOT()#\"\
					strLevel[currTab] = elem\
				end		-- if string.find(strLevel[currTab],\" or \") or string.find(strLevel[currTab],\" OR \") then ends\
			end \
		end		-- while currTab do ends\
		-- Now recurse boolTab to substitute all the strings back\
		local t = boolTab\
		if strSubMap[t.Item] then\
			t.Item = string.match(strSubMap[t.Item],\"'(.-)'\")\
		end\
		if t.Children then\
			-- Traverse the table to fill up the tree\
			local tIndex = {}\
			tIndex[t] = 1\
			while tIndex[t] <= #t.Children or t.Parent do\
				if tIndex[t] > #t.Children then\
					tIndex[t] = nil\
					t = t.Parent\
				else\
					-- Handle the current element\
					if strSubMap[t.Children[tIndex[t]].Item] then\
						t.Children[tIndex[t]].Item = strSubMap[t.Children[tIndex[t]].Item]:match(\"'(.-)'\")\
					end\
					tIndex[t] = tIndex[t] + 1\
					-- Check if this has children\
					if t.Children[tIndex[t]-1].Children then\
						-- go deeper in the hierarchy\
						t = t.Children[tIndex[t]-1]\
						tIndex[t] = 1\
					end\
				end		-- if tIndex[t] > #t then ends\
			end		-- while tIndex[t] <= #t and t.Parent do ends\
		end	-- if t.Children then ends\
		return boolTab\
	end		-- function convertBoolStr2Tab(str) ends\
\
	-- Function to set the boolean string expression in the tree\
	local function setExpression(o,str)\
		local t = convertBoolStr2Tab(str)\
		local tIndex = {}\
		local tNode = {}\
		local itemText = function(itemStr)\
			-- To return the item text\
			if itemStr == \"#AND#\" then\
				return \"(AND)\"\
			elseif itemStr == \"#OR#\" then\
				return \"(OR)\"\
			elseif itemStr == \"#NOT()#\" then\
				return \"NOT()\"\
			elseif itemStr == \"#NOT(AND)#\" then\
				return \"NOT(AND)\"\
			elseif itemStr == \"#NOT(OR)#\" then\
				return \"NOT(OR)\"\
			else\
				return itemStr\
			end\
		end\
		-- Clear the control\
		o:ResetCtrl()\
		tNode[t] = o.SelTree:AppendItem(o.SelTree:GetRootItem(),itemText(t.Item))\
		if t.Children then\
			-- Traverse the table to fill up the tree\
			tIndex[t] = 1\
			while tIndex[t] <= #t.Children or t.Parent do\
				if tIndex[t] > #t.Children then\
					tIndex[t] = nil\
					t = t.Parent\
				else\
					-- Handle the current element\
					local parentNode \
					parentNode = tNode[t]\
					tNode[t.Children[tIndex[t]]] = o.SelTree:AppendItem(parentNode,itemText(t.Children[tIndex[t]].Item)) \
					tIndex[t] = tIndex[t] + 1\
					-- Check if this has children\
					if t.Children[tIndex[t]-1].Children then\
						-- go deeper in the hierarchy\
						t = t.Children[tIndex[t]-1]\
						tIndex[t] = 1\
					end\
				end		-- if tIndex[t] > #t then ends\
			end		-- while tIndex[t] <= #t and t.Parent do ends\
		end	-- if t.Children then ends\
		o.SelTree:Expand(o.SelTree:GetRootItem())\
	end		-- local function setExpression(o,str) ends\
	\
	local treeRecRef\
	local treeRecurse = function(tree,node)\
		local itemText = tree:GetItemText(node) \
		if itemText == \"(AND)\" or itemText == \"(OR)\" or itemText == \"NOT(OR)\" or itemText == \"NOT(AND)\" then\
			local retText = \"(\" \
			local logic = string.lower(\" \"..string.match(itemText,\"%((.-)%)\")..\" \")\
			if string.sub(itemText,1,3) == \"NOT\" then\
				retText = \"not(\"\
			end\
			local currNode = tree:GetFirstChild(node)\
			retText = retText..treeRecRef(tree,currNode)\
			currNode = tree:GetNextSibling(currNode)\
			while currNode:IsOk() do\
				retText = retText..logic..treeRecRef(tree,currNode)\
				currNode = tree:GetNextSibling(currNode)\
			end\
			return retText..\")\"\
		elseif itemText == \"NOT()\" then\
			return \"not(\"..treeRecRef(tree,tree:GetFirstChild(node))..\")\"\
		else\
			return \"'\"..itemText..\"'\"\
		end\
	end\
	treeRecRef = treeRecurse\
\
	local BooleanExpression = function(o)\
		local tree = o.SelTree\
		local currNode = tree:GetFirstChild(tree:GetRootItem())\
		if currNode:IsOk() then\
			local expr = treeRecurse(tree,currNode)\
			return expr\
		else\
			return nil\
		end		\
	end\
		\
	local CopyTree = function(treeObj,srcItem,destItem)\
		-- This will copy the srcItem and its child tree to as a child of destItem\
		if not srcItem:IsOk() or not destItem:IsOk() then\
			error(\"Expected wxTreeItemIds\",2)\
		end\
		local tree = treeObj.SelTree\
		local currSrcNode = srcItem\
		local currDestNode = destItem\
		-- Copy the currSrcNode under the currDestNode\
		currDestNode = tree:AppendItem(currDestNode,tree:GetItemText(currSrcNode))\
		-- Check if any children\
		if tree:ItemHasChildren(currSrcNode) then\
			currSrcNode = tree:GetFirstChild(currSrcNode)\
			while true do\
				-- Copy the currSrcNode under the currDestNode\
				local currNode = tree:AppendItem(currDestNode,tree:GetItemText(currSrcNode))\
				-- Check if any children\
				if tree:ItemHasChildren(currSrcNode) then\
					currDestNode = currNode\
					currSrcNode = tree:GetFirstChild(currSrcNode)\
				elseif tree:GetNextSibling(currSrcNode):IsOk() then\
					-- There are more items in the same level\
					currSrcNode = tree:GetNextSibling(currSrcNode)\
				else\
					-- No children and no further siblings so go up\
					currSrcNode = tree:GetItemParent(currSrcNode)\
					currDestNode = tree:GetItemParent(currDestNode)\
					while not tree:GetNextSibling(currSrcNode):IsOk() and not(currSrcNode:GetValue() == srcItem:GetValue()) do\
						currSrcNode = tree:GetItemParent(currSrcNode)\
						currDestNode = tree:GetItemParent(currDestNode)\
					end\
					if currSrcNode:GetValue() == srcItem:GetValue() then\
						break\
					end\
					currSrcNode = tree:GetNextSibling(currSrcNode)\
				end		-- if tree:ItemHasChildren(currSrcNode) then ends\
			end		-- while true do ends\
		end		-- if tree:ItemHasChildren(currSrcNode) then ends\
	end\
	\
	local DelTree = function(treeObj,item)\
		if not item:IsOk() then\
			error(\"Expected proper wxTreeItemId\",2)\
		end\
		local tree = treeObj.SelTree\
		local currNode = item\
		if tree:ItemHasChildren(currNode) then\
			currNode = tree:GetFirstChild(currNode)\
			while true do\
				-- Check if any children\
				if tree:ItemHasChildren(currNode) then\
					currNode = tree:GetFirstChild(currNode)\
				elseif tree:GetNextSibling(currNode):IsOk() then\
					-- delete this node\
					-- There are more items in the same level\
					local next = tree:GetNextSibling(currNode)\
					tree:Delete(currNode)\
					currNode = next \
				else\
					-- No children and no further siblings so delete and go up\
					local parent = tree:GetItemParent(currNode)\
					tree:Delete(currNode)\
					currNode = parent\
					while not tree:GetNextSibling(currNode):IsOk() and not(currNode:GetValue() == item:GetValue()) do\
						parent = tree:GetItemParent(currNode)\
						tree:Delete(currNode)\
						currNode = parent\
					end\
					if currNode:GetValue() == item:GetValue() then\
						break\
					end\
					currNode = tree:GetNextSibling(currNode)\
				end		-- if tree:ItemHasChildren(currSrcNode) then ends\
			end		-- while true do ends\
		end		-- if tree:ItemHasChildren(currNode) then ends\
		tree:Delete(currNode)		\
	end\
	\
	local ResetCtrl = function(o)\
		if o.SelTree:GetFirstChild(o.SelTree:GetRootItem()):IsOk() then\
			DelTree(o,o.SelTree:GetFirstChild(o.SelTree:GetRootItem()))\
		end\
	end\
	\
	local DeletePress = function(event)\
		setfenv(1,package.loaded[modname])\
		local ob = objMap[event:GetId()]\
		local Sel = ob.object.SelTree:GetSelections(Sel)	\
		-- Check if anything selected\
		if #Sel == 0 then\
			return nil\
		end\
		-- Get list of Parents\
		local parents = {}\
		-- Delete all selected\
		for i=1,#Sel do\
			local parent = ob.object.SelTree:GetItemParent(Sel[i])\
			local addParent = true\
			for j = 1,#parents do\
				if parents[j]:GetValue() == parent:GetValue() then\
					addParent = nil\
					break\
				end\
			end\
			if addParent then\
				parents[#parents + 1] = parent\
			end\
			if Sel[i]:GetValue() ~= ob.object.SelTree:GetRootItem():GetValue() then\
				DelTree(ob.object,Sel[i])\
			end\
		end\
		-- Check for any parents that are logic nodes with only 1 child under them\
		for i = 1,#parents do\
			if ob.object.SelTree:GetChildrenCount(parents[i],false) == 1 then\
				local nodeText = ob.object.SelTree:GetItemText(parents[i])\
				if nodeText == \"(OR)\" or nodeText == \"(AND)\" then\
					-- This is a logic node without NOT()\
					-- Delete the Parent and move the children up 1 level\
					-- Move it up the hierarchy\
					local pParent = ob.object.SelTree:GetItemParent(parents[i])\
					-- Copy all children to pParent\
					local currNode = ob.object.SelTree:GetFirstChild(parents[i])\
					while currNode:IsOk() do\
						CopyTree(ob.object,currNode,pParent)\
						currNode = ob.object.SelTree:GetNextSibling(currNode)\
					end\
					DelTree(ob.object,parents[i])\
				elseif nodeText == \"NOT(OR)\" or nodeText == \"NOT(AND)\"  then\
					-- Just change the text to NOT()\
					ob.object.SelTree:SetItemText(node,\"NOT(OR)\")\
				end\
			end\
		end\
		if ob.object.SelTree:GetChildrenCount(ob.object.SelTree:GetRootItem()) == 1 then\
			ob.object.DeleteButton:Disable()\
		end\
	end\
	\
	local NegatePress = function(event)\
		setfenv(1,package.loaded[modname])\
		local ob = objMap[event:GetId()]\
		local Sel = ob.object.SelTree:GetSelections(Sel)	\
		-- Check if anything selected\
		if #Sel == 0 then\
			return nil\
		end\
		local parent = ob.object.SelTree:GetItemParent(Sel[1])\
		for i = 2,#Sel do\
			if ob.object.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\
				wx.wxMessageBox(\"For multiple selection negate they must all be under the same node.\",\"Selections not at the same level\", wx.wxOK + wx.wxCENTRE, o.parent)\
				return\
			end\
		end\
		if parent:IsOk() then\
			if #Sel == 1 then\
				-- Single Selection\
				-- Check if this is a Logic node\
				local nodeText = ob.object.SelTree:GetItemText(Sel[1])\
				if nodeText == \"(OR)\" or nodeText == \"(AND)\" or nodeText == \"NOT(OR)\" or nodeText == \"NOT(AND)\" or nodeText == \"NOT()\" then\
					-- Just negation of the node has to be done\
					local node = Sel[1]\
					if nodeText == \"(OR)\" then\
						ob.object.SelTree:SetItemText(node,\"NOT(OR)\")\
					elseif nodeText == \"(AND)\" then\
						ob.object.SelTree:SetItemText(node,\"NOT(AND)\")\
					elseif nodeText == \"NOT(OR)\" then\
						ob.object.SelTree:SetItemText(node,\"(OR)\")\
					elseif nodeText == \"NOT(AND)\" then\
						ob.object.SelTree:SetItemText(node,\"(AND)\")\
					else\
						-- NOT()\
						-- Move it up the hierarchy\
						local pParent = ob.object.SelTree:GetItemParent(node)\
						-- Copy all children to pParent\
						local currNode = ob.object.SelTree:GetFirstChild(node)\
						while currNode:IsOk() do\
							CopyTree(ob.object,currNode,pParent)\
							currNode = ob.object.SelTree:GetNextSibling(currNode)\
						end\
						DelTree(ob.object,node)\
					end		-- if parentText == \"(OR)\" then ends here\
				-- Check if the parent just has this child\
				elseif ob.object.SelTree:GetChildrenCount(parent,false) == 1 then\
					local node = parent\
					nodeText = ob.object.SelTree:GetItemText(parent)\
					if nodeText == \"(OR)\" then\
						ob.object.SelTree:SetItemText(node,\"NOT(OR)\")\
					elseif nodeText == \"(AND)\" then\
						ob.object.SelTree:SetItemText(node,\"NOT(AND)\")\
					elseif nodeText == \"NOT(OR)\" then\
						ob.object.SelTree:SetItemText(node,\"(OR)\")\
					elseif nodeText == \"NOT(AND)\" then\
						ob.object.SelTree:SetItemText(node,\"(AND)\")\
					else\
						-- NOT()\
						-- Move it up the hierarchy\
						local pParent = ob.object.SelTree:GetItemParent(node)\
						CopyTree(ob.object,Sel[1],pParent)\
						DelTree(ob.object,node)\
					end		-- if parentText == \"(OR)\" then ends here\
				else\
					local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\
					CopyTree(ob.object,Sel[1],currNode)\
					DelTree(ob.object,Sel[1])\
				end		-- if type of node - Logic Node, Single Child node of a parent or one of many children\
			else\
				-- Multiple Selection\
				-- Check if the parent just has these children\
				local parentText = ob.object.SelTree:GetItemText(parent)\
				if ob.object.SelTree:GetChildrenCount(parent,false) == #Sel then\
					-- Just modify the parent text\
					if parentText == \"(OR)\" then\
						ob.object.SelTree:SetItemText(parent,\"NOT(OR)\")\
					elseif parentText == \"(AND)\" then\
						ob.object.SelTree:SetItemText(parent,\"NOT(AND)\")\
					elseif parentText == \"NOT(OR)\" then\
						ob.object.SelTree:SetItemText(parent,\"(OR)\")\
					else -- parentText == \"NOT(AND)\" \
						ob.object.SelTree:SetItemText(parent,\"(AND)\")\
					end\
				else\
					-- First move the selections to a correct new node\
					if parentText == \"(OR)\" or parentText == \"NOT(OR)\" then\
						parentText = \"NOT(OR)\"\
					elseif parentText == \"(AND)\" or parentText == \"NOT(AND)\" then\
						parentText = \"NOT(AND)\" \
					end\
					parent = ob.object.SelTree:AppendItem(ob.object.SelTree:GetItemParent(Sel[1]),parentText)\
					for i = 1,#Sel do\
						CopyTree(ob.object,Sel[i],parent)\
						DelTree(ob.object,Sel[i])\
					end\
				end\
			end\
		end	-- if parent:IsOk() then\
	end\
	\
	local LogicPress = function(event)\
		setfenv(1,package.loaded[modname])\
		local ob = objMap[event:GetId()]\
		-- Get the Logic Unit\
		local unit = ob.object.getInfo()\
		if not unit then\
			return nil\
		end\
		\
		local root = ob.object.SelTree:GetRootItem()\
		if ob.object.SelTree:GetCount() == 1 then\
			-- Just add this first object\
			local currNode = ob.object.SelTree:AppendItem(root,unit)\
			ob.object.SelTree:Expand(root)\
			return nil\
		end\
		-- More than 1 item in the tree so now find the selections and  modify the tree\
		local Sel = ob.object.SelTree:GetSelections(Sel)\
		-- Check if anything selected\
		if #Sel == 0 then\
			return nil\
		end\
		\
		-- Check if parent of all selections is the same	\
		if #Sel > 1 then\
        	local parent = ob.object.SelTree:GetItemParent(Sel[1])\
        	for i = 2,#Sel do\
        		if ob.object.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\
        			-- Parent is not common. \
        			wx.wxMessageBox(\"All selected items not siblings!\",\"Error applying operation\", wx.wxICON_ERROR)\
        			return nil\
        		end\
        	end\
        end\
		\
		-- Check if root node selected\
		if #Sel == 1 and ob.object.SelTree:GetRootItem():GetValue() == Sel[1]:GetValue() then\
			-- Root item selected clear Sel and fill up with all children of root\
			Sel = {}\
			local node = ob.object.SelTree:GetFirstChild(ob.object.SelTree:GetRootItem())\
			Sel[#Sel + 1] = node\
			node = ob.object.SelTree:GetNextSibling(node)\
			while node:IsOk() do\
				Sel[#Sel + 1] = node\
				node = ob.object.SelTree:GetNextSibling(node)\
			end\
		end\
		local added = nil\
		if #Sel > 1 then\
			-- Check if all children selected\
			local parent = ob.object.SelTree:GetItemParent(Sel[1])\
			if #Sel == ob.object.SelTree:GetChildrenCount(parent,false) then\
				-- All children of parent are selected\
				-- Check if the unit can be added under the parent itself\
				local parentText = ob.object.SelTree:GetItemText(parent)\
				if ((ob.button == \"AND\" or ob.button == \"NAND\" or ob.button == \"ANDN\" or ob.button == \"NANDN\") and \
						(parentText == \"(AND)\" or parentText == \"NOT(AND)\")) or\
				   ((ob.button == \"OR\" or ob.button == \"NOR\" or ob.button == \"ORN\" or ob.button == \"NORN\") and \
				   		(parentText == \"(OR)\" or parentText == \"NOT(OR)\")) then\
					-- Add the unit under parent\
					if ob.button == \"AND\" or ob.button == \"OR\" then\
						-- Add to parent directly\
						ob.object.SelTree:AppendItem(parent,unit)\
					elseif ob.button == \"NAND\" or ob.button == \"NOR\" then\
						-- Add to parent by negating first\
						local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\
						ob.object.SelTree:AppendItem(currNode,unit)\
					elseif ob.button == \"ANDN\" or ob.button == \"ORN\" or ob.button == \"NANDN\" or ob.button == \"NORN\" then\
						if parentText == \"(AND)\" or parentText == \"(OR)\"then\
							-- Move all selected to a negated subnode\
							local newPText \
							if parentText == \"(OR)\" then\
								newPText = \"NOT(OR)\"\
							elseif parentText == \"(AND)\" then\
								newPText = \"NOT(AND)\" \
							end\
							local newParent = ob.object.SelTree:AppendItem(parent,newPText)\
							for i = 1,#Sel do\
								CopyTree(ob.object,Sel[i],newParent)\
								DelTree(ob.object,Sel[i])\
							end\
						elseif parentText == \"NOT(AND)\" then\
							ob.object.SelTree:SetItemText(parent,\"(AND)\")\
						elseif parentText == \"NOT(OR)\" then\
							ob.object.SelTree:SetItemText(parent,\"(OR)\")\
						end\
						-- Now add the unit to the parent\
						if ob.button == \"NANDN\" or ob.button == \"NORN\" then\
							local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\
							ob.object.SelTree:AppendItem(currNode,unit)\
						else\
							ob.object.SelTree:AppendItem(parent,unit)\
						end\
					end\
					added = true\
				end\
			end		-- if #Sel < ob.object.SelTree:GetChildrenCount(parent) then ends\
			if not added then\
				-- Move all selected to sub node\
				local parentText = ob.object.SelTree:GetItemText(parent)\
				if parentText == \"(OR)\" or parentText == \"NOT(OR)\" then\
					parentText = \"(OR)\"\
				elseif parentText == \"(AND)\" or parentText == \"NOT(AND)\" then\
					parentText = \"(AND)\" \
				end\
				parent = ob.object.SelTree:AppendItem(ob.object.SelTree:GetItemParent(Sel[1]),parentText)\
				for i = 1,#Sel do\
					CopyTree(ob.object,Sel[i],parent)\
					DelTree(ob.object,Sel[i])\
				end\
				Sel = {parent}\
			end\
		end\
		if not added then\
			-- Single item selection case\
			-- Check if this is a logic node and the unit can directly be added to it\
			local selText = ob.object.SelTree:GetItemText(Sel[1])\
			if selText == \"(OR)\" and (ob.button == \"OR\" or ob.button == \"NOR\") then\
				if ob.button == \"OR\" then\
					-- Add to parent directly\
					ob.object.SelTree:AppendItem(Sel[1],unit)\
				else\
					-- Add to parent by negating first\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\
					ob.object.SelTree:AppendItem(currNode,unit)\
				end\
			elseif  selText == \"(AND)\" and (ob.button == \"AND\" or ob.button == \"NAND\") then\
				if ob.button == \"AND\" then\
					-- Add to parent directly\
					ob.object.SelTree:AppendItem(Sel[1],unit)\
				else\
					-- Add to parent by negating first\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\
					ob.object.SelTree:AppendItem(currNode,unit)\
				end\
			elseif selText == \"NOT(OR)\" and (ob.button == \"ORN\" or ob.button == \"NORN\") then\
				if ob.button == \"ORN\" then\
					-- Add to parent directly\
					ob.object.SelTree:AppendItem(Sel[1],unit)\
				else\
					-- Add to parent by negating first\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\
					ob.object.SelTree:AppendItem(currNode,unit)\
				end\
				ob.object.SelTree:SetItemText(Sel[1],\"(OR)\")\
			elseif selText == \"NOT(AND)\" and (ob.button == \"ANDN\" or ob.button == \"NANDN\") then\
				if ob.button == \"ANDN\" then\
					-- Add to parent directly\
					ob.object.SelTree:AppendItem(Sel[1],unit)\
				else\
					-- Add to parent by negating first\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\
					ob.object.SelTree:AppendItem(currNode,unit)\
				end\
				ob.object.SelTree:SetItemText(Sel[1],\"(AND)\")\
			elseif selText == \"NOT()\" and (ob.button == \"ANDN\" or ob.button == \"NANDN\" or ob.button == \"ORN\" or ob.button == \"NORN\")then\
				if ob.button == \"ANDN\" then\
					ob.object.SelTree:SetItemText(Sel[1],\"(AND)\")\
					ob.object.SelTree:AppendItem(Sel[1],unit)\
				elseif ob.button == \"NANDN\" then\
					ob.object.SelTree:SetItemText(Sel[1],\"(AND)\")\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\
					ob.object.SelTree:AppendItem(currNode,unit)\
				elseif ob.button == \"ORN\" then\
					ob.object.SelTree:SetItemText(Sel[1],\"(OR)\")\
					ob.object.SelTree:AppendItem(Sel[1],unit)\
				else\
					ob.object.SelTree:SetItemText(Sel[1],\"(OR)\")\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\
					ob.object.SelTree:AppendItem(currNode,unit)\
				end\
			else\
				-- Unit cannot be added to the selected node since that is also a unit\
				local parent = ob.object.SelTree:GetItemParent(Sel[1])\
				local parentText = ob.object.SelTree:GetItemText(parent)\
				-- Handle the directly adding unit to parent cases\
				if (parentText == \"(OR)\" or parentText == \"NOT(OR)\") and  (ob.button == \"OR\" or ob.button == \"NOR\") then\
					if ob.button == \"OR\" then\
						-- Add to parent directly\
						ob.object.SelTree:AppendItem(parent,unit)\
					else\
						-- Add to parent by negating first\
						local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\
						ob.object.SelTree:AppendItem(currNode,unit)\
					end\
				elseif (parentText == \"(AND)\" or parentText == \"NOT(AND)\") and (ob.button == \"AND\" or ob.button == \"NAND\") then\
					if ob.button == \"AND\" then\
						-- Add to parent directly\
						ob.object.SelTree:AppendItem(parent,unit)\
					else\
						-- Add to parent by negating first\
						local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\
						ob.object.SelTree:AppendItem(currNode,unit)\
					end\
				elseif parentText == \"NOT()\" and (ob.button == \"AND\" or ob.button == \"NAND\" or ob.button == \"OR\" or ob.button == \"NOR\") then\
					-- parentText = \"NOT()\"\
					-- Change Parent text\
					if ob.button == \"NAND\" or ob.button == \"AND\" then\
						ob.object.SelTree:SetItemText(parent,\"NOT(AND)\")\
						if ob.button == \"AND\" then\
							-- Add to parent directly\
							ob.object.SelTree:AppendItem(parent,unit)\
						else\
							-- Add to parent by negating first\
							local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\
							ob.object.SelTree:AppendItem(currNode,unit)\
						end\
					elseif ob.button==\"NOR\" or ob.button == \"OR\" then\
						ob.object.SelTree:SetItemText(parent,\"NOT(OR)\")\
						if ob.button == \"OR\" then\
							-- Add to parent directly\
							ob.object.SelTree:AppendItem(parent,unit)\
						else\
							-- Add to parent by negating first\
							local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\
							ob.object.SelTree:AppendItem(currNode,unit)\
						end\
					end\
				else\
					-- Now we need to move this single selected node to a new fresh node in its place and add unit also to that node\
					if ob.button == \"AND\" or ob.button == \"NAND\" or ob.button == \"ANDN\" or ob.button == \"NANDN\" then\
						parentText = \"(AND)\"\
					elseif ob.button == \"OR\" or ob.button == \"NOR\" or ob.button == \"ORN\" or ob.button == \"NORN\" then\
						parentText = \"(OR)\"\
					end\
					local currNode = ob.object.SelTree:AppendItem(parent,parentText)\
					if ob.button == \"ANDN\" or ob.button ==\"NANDN\" or ob.button == \"ORN\" or ob.button == \"NORN\" then\
						local negNode = ob.object.SelTree:AppendItem(currNode,\"NOT()\")\
						CopyTree(ob.object,Sel[1],negNode)\
					else \
						CopyTree(ob.object,Sel[1],currNode)\
					end		\
					DelTree(ob.object,Sel[1])\
					-- Add the unit\
					if ob.button == \"AND\" or ob.button == \"OR\" or ob.button == \"ANDN\" or ob.button == \"ORN\" then\
						-- Add to parent directly\
						ob.object.SelTree:AppendItem(currNode,unit)\
					else\
						-- Add to parent by negating first\
						local negNode = ob.object.SelTree:AppendItem(currNode,\"NOT()\")\
						ob.object.SelTree:AppendItem(negNode,unit)\
					end\
				end		-- if (parentText == \"(OR)\" or parentText == \"NOT(OR)\") and  (ob.button == \"OR\" or ob.button == \"NOR\") then ends\
			end		-- if selText == \"(OR)\" and (ob.button == \"OR\" or ob.button == \"NOR\") then ends\
		end	-- if not added then ends\
		--print(ob.object,ob.button)\
		--print(BooleanTreeCtrl.BooleanExpression(ob.object.SelTree))	\
	end\
	\
--[[	local TreeSelChanged = function(event)\
		setfenv(1,package.loaded[modname])\
		local o = objMap[event:GetId()]\
        \
        -- Update the Delete Button status\
        local Sel = o.SelTree:GetSelections(Sel)\
        if #Sel == 0 then\
        	o.prevSel = {}\
        	o.DeleteButton:Disable()\
        	return nil\
        end\
        o.DeleteButton:Enable(true)\
    	-- Check here if there are more than 1 difference between Sel and prevSel\
    	local diff = 0\
    	for i = 1,#Sel do\
    		local found = nil\
    		for j = 1,#o.prevSel do\
    			if Sel[i]:GetValue() == o.prevSel[j]:GetValue() then\
    				found = true\
    				break\
    			end\
    		end\
    		if not found then\
    			diff = diff + 1\
    		end\
    	end\
    	-- diff has number of elements in Sel but nout found in o.prevSel\
    	for i = 1,#o.prevSel do\
    		local found = nil\
    		for j = 1,#Sel do\
    			if Sel[j]:GetValue() == o.prevSel[i]:GetValue() then\
    				found = true\
    				break\
    			end\
    		end\
    		if not found then\
    			diff = diff + 1\
    		end\
    	end\
        if #Sel > 1 and diff == 1 then\
        	-- Check here if the selection needs to be modified to keep at the same level\
        	local parent = o.SelTree:GetItemParent(Sel[1])\
        	for i = 2,#Sel do\
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\
        			-- Need to modify the selection here\
        			-- Find which element was selected last here\
        			local newElem = nil\
        			for j = 1,#Sel do\
        				local found = nil\
        				for k = 1,#o.prevSel do\
        					if Sel[j]:GetValue() == o.prevSel[k]:GetValue() then\
        						found = true\
        						break\
        					end\
        				end\
        				if not found then\
        					newElem = Sel[j]\
        					break\
        				end\
        			end		-- for j = 1,#Sel do ends\
        			-- Now newElem has the newest element so deselect everything and select that\
        			for j = 1,#Sel do\
        				o.SelTree:SelectItem(Sel[j],false)\
        			end\
        			o.SelTree:SelectItem(newElem,true)\
	        		Sel = o.SelTree:GetSelections(Sel)\
					o.prevSel = {}\
					for i = 1,#Sel do\
						o.prevSel[i] = Sel[i]\
					end\
        			break\
        		end		-- if o.SelTree:GetItemParent(Sel[i]) ~= parent then ends\
        	end		-- for i = 2,#Sel do ends\
        end		-- if #Sel > 1 then\
--        if #Sel > 1 or o.SelTree:ItemHasChildren(Sel[1]) then\
--        	o.DeleteButton:Disable()\
--        else\
--        	o.DeleteButton:Enable(true)\
--        end\
		-- Populate prevSel table\
    	if diff == 1 and math.abs(#Sel-#o.prevSel) == 1 then\
			o.prevSel = {}\
			for i = 1,#Sel do\
				o.prevSel[i] = Sel[i]\
			end\
		elseif diff > 1 and math.abs(#Sel-#o.prevSel) == diff then\
			-- Selection made by Shift Key check if at same hierarchy then update prevSel otherwise rever to prevSel\
        	local parent = o.SelTree:GetItemParent(Sel[1])\
        	local updatePrev = true\
        	for i = 2,#Sel do\
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\
        			-- Now newElem has the newest element so deselect everything and select that\
        			for j = 1,#Sel do\
        				o.SelTree:SelectItem(Sel[j],false)\
        			end\
        			for j = 1,#o.prevSel do\
        				o.SelTree:SelectItem(o.prevSel[j],true)\
        			end\
        			updatePrev = false\
        			break\
        		end		-- if o.SelTree:GetItemParent(Sel[i]) ~= parent then ends\
        	end		-- for i = 2,#Sel do ends	\
        	if updatePrev then		\
				o.prevSel = {}\
				for i = 1,#Sel do\
					o.prevSel[i] = Sel[i]\
				end\
			end\
		end\
		\
		--event:Skip()\
		--print(o.SelTree:GetItemText(item))\
	end,]]\
	\
	local TreeSelChanged = function(event)\
		setfenv(1,package.loaded[modname])\
		local o = objMap[event:GetId()]\
        \
        -- Update the Delete Button status\
        local Sel = o.SelTree:GetSelections(Sel)\
        if #Sel == 0 then\
        	o.prevSel = {}\
        	o.DeleteButton:Disable()\
        	o.NegateButton:Disable()\
        	return nil\
        end\
        o.DeleteButton:Enable(true)\
       	o.NegateButton:Enable(true)\
		-- Check if parent of all selections is the same	\
		if #Sel > 1 then\
        	local parent = o.SelTree:GetItemParent(Sel[1])\
        	for i = 2,#Sel do\
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\
        			-- Deselect everything\
        			for j = 1,#Sel do\
        				o.SelTree:SelectItem(Sel[j],false)\
        			end\
        			-- Select the items with the largest parent\
        			local parents = {}	-- To store parents and their numbers\
        			for j =1,#Sel do\
        				local found = nil\
        				for k = 1,#parents do\
        					if o.SelTree:GetItemParent(Sel[j]):GetValue() == parents[k].ID:GetValue() then\
        						parents[k].count = parents[k].count + 1\
        						found = true\
        						break\
        					end\
        				end\
        				if not found then\
        					parents[#parents + 1] = {ID = o.SelTree:GetItemParent(Sel[j]), count = 1}\
        				end\
        			end\
        			-- Find parent with largest number of children\
        			local index = 1\
        			for j = 2,#parents do\
        				if parents[j].count > parents[index].count then\
        					index = j\
        				end\
        			end\
        			-- Select all items with parents[index].ID as parent\
        			for j = 1,#Sel do\
        				if o.SelTree:GetItemParent(Sel[j]):GetValue() == parents[index].ID:GetValue() then\
        					o.SelTree:SelectItem(Sel[j],true)\
        				end\
        			end		-- for j = 1,#Sel do ends\
        		end		-- if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then ends\
        	end		-- for i = 2,#Sel do ends\
        end		-- if #Sel > 1 then ends\
        event:Skip()\
	end\
	\
	BooleanTreeCtrl = function(parent,sizer,getInfoFunc)\
		if not parent or not sizer or not getInfoFunc or type(getInfoFunc)~=\"function\" then\
			return nil\
		end\
		local o = {ResetCtrl=ResetCtrl,BooleanExpression=BooleanExpression, setExpression = setExpression}\
		o.getInfo = getInfoFunc\
		o.prevSel = {}\
		o.parent = parent\
		local ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
			local ID = NewID()\
			o.ANDButton = wx.wxButton(parent, ID, \"AND\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = {object=o,button=\"AND\"}\
			ButtonSizer:Add(o.ANDButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			ID = NewID()\
			o.ORButton = wx.wxButton(parent, ID, \"OR\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = {object=o,button=\"OR\"}\
			ButtonSizer:Add(o.ORButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			ID = NewID()\
			o.NANDButton = wx.wxButton(parent, ID, \"NOT() AND\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = {object=o,button=\"NAND\"}\
			ButtonSizer:Add(o.NANDButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			ID = NewID()\
			o.NORButton = wx.wxButton(parent, ID, \"NOT() OR\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = {object=o,button=\"NOR\"}\
			ButtonSizer:Add(o.NORButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			ID = NewID()\
			o.ANDNButton = wx.wxButton(parent, ID, \"AND NOT\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = {object=o,button=\"ANDN\"}\
			ButtonSizer:Add(o.ANDNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			ID = NewID()\
			o.ORNButton = wx.wxButton(parent, ID, \"OR NOT\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = {object=o,button=\"ORN\"}\
			ButtonSizer:Add(o.ORNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			ID = NewID()\
			o.NANDNButton = wx.wxButton(parent, ID, \"NOT() AND NOT\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = {object=o,button=\"NANDN\"}\
			ButtonSizer:Add(o.NANDNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			ID = NewID()\
			o.NORNButton = wx.wxButton(parent, ID, \"NOT() OR NOT\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = {object=o,button=\"NORN\"}\
			ButtonSizer:Add(o.NORNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			local treeSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
				ID = NewID()\
				o.SelTree = wx.wxTreeCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,bit.bor(wx.wxTR_HAS_BUTTONS,wx.wxTR_MULTIPLE))\
				objMap[ID] = o\
				-- Add the root\
				local root = o.SelTree:AddRoot(\"Expressions\")\
				o.SelTree:SelectItem(root)\
			treeSizer:Add(o.SelTree, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				-- Add the Delete and Negate Buttons\
				ButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					ID = NewID()\
					o.DeleteButton = wx.wxButton(parent, ID, \"Delete\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
					objMap[ID] = {object=o,button=\"Delete\"}\
				ButtonSizer:Add(o.DeleteButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				o.DeleteButton:Disable()\
					ID = NewID()\
					o.NegateButton = wx.wxButton(parent, ID, \"Negate\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
					objMap[ID] = {object=o,button=\"Negate\"}\
				ButtonSizer:Add(o.NegateButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				o.NegateButton:Disable()\
			treeSizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)		\
		sizer:Add(treeSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	\
		-- Connect the buttons to the event handlers\
		o.ANDButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\
		o.ORButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\
		o.NANDButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\
		o.NORButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\
		o.ANDNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\
		o.ORNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\
		o.NANDNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\
		o.NORNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\
		o.DeleteButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,DeletePress)\
		o.NegateButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,NegatePress)\
		\
		-- Connect the tree to the left click event\
		o.SelTree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, TreeSelChanged)\
		return o\
	end\
end		-- BooleanTreeCtrl ends\
\
-- Control to select date Range\
do\
	local objMap = {}\
	SelectDateRangeCtrl = function(parent,numInstances,returnFunc)\
		if not objMap[parent] then\
			objMap[parent] = 1\
		elseif objMap[parent] >= numInstances then\
			return false\
		else\
			objMap[parent] = objMap[parent] + 1\
		end\
		local drFrame = wx.wxFrame(parent, wx.wxID_ANY, \"Date Range Selection\", wx.wxDefaultPosition,\
			wx.wxDefaultSize, wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION\
			+ wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN)\
		local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
		local calSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
		local fromSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
		local label = wx.wxStaticText(drFrame, wx.wxID_ANY, \"From:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
		fromSizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		local fromDate = wx.wxCalendarCtrl(drFrame,wx.wxID_ANY)\
		fromSizer:Add(fromDate, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
		local toSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
		label = wx.wxStaticText(drFrame, wx.wxID_ANY, \"To:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
		toSizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		local toDate = wx.wxCalendarCtrl(drFrame,wx.wxID_ANY)\
		toSizer:Add(toDate, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		\
		calSizer:Add(fromSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		calSizer:Add(toSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		\
		-- Add Buttons\
		local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
		local selButton = wx.wxButton(drFrame, wx.wxID_ANY, \"Select\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
		buttonSizer:Add(selButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
		local CancelButton = wx.wxButton(drFrame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
		buttonSizer:Add(CancelButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
		\
		\
		MainSizer:Add(calSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		drFrame:SetSizer(MainSizer)\
		MainSizer:SetSizeHints(drFrame)\
	    drFrame:Layout() -- help sizing the windows before being shown\
	    drFrame:Show(true)\
	    \
		selButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,function(event)\
			setfenv(1,package.loaded[modname])\
			returnFunc(fromDate:GetDate():Format(\"%m/%d/%Y\")..\"-\"..toDate:GetDate():Format(\"%m/%d/%Y\"))\
			drFrame:Close()\
			objMap[parent] = objMap[parent] - 1\
		end	\
		)\
		CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,function(event)\
			setfenv(1,package.loaded[modname])\
			drFrame:Close() \
			objMap[parent] = objMap[parent] - 1\
		end\
		)	    	\
	end		-- display = function(parent,numInstances,returnFunc) ends\
end		-- SelectDateRangeCtrl ends\
\
-- Date Range Selection Control\
do\
	local objMap = {}		-- Private Static Variable\
	\
	local getSelectedItems = function(o)\
		local selItems = {}\
		local SelList = o.list\
		local itemNum = -1\
		while SelList:GetNextItem(itemNum) ~= -1 do\
			itemNum = SelList:GetNextItem(itemNum)\
			local itemText = SelList:GetItemText(itemNum)\
			selItems[#selItems + 1] = itemText\
		end\
		-- Finally Check if none selection box exists\
		if o.CheckBox and o.CheckBox:GetValue() then\
			selItems[0] = \"true\"\
		end\
		return selItems\
	end\
\
    local addRange = function(o,range)\
		-- Check if the Item exists in the list control\
		local itemNum = -1\
		local conditionList = false\
		while o.list:GetNextItem(itemNum) ~= -1 do\
			local prevItemNum = itemNum\
			itemNum = o.list:GetNextItem(itemNum)\
			local itemText = o.list:GetItemText(itemNum)\
			-- Now compare the dateRanges\
			local comp = compareDateRanges(range,itemText)\
			if comp == 1 then\
				-- Ranges are same, do nothing\
				drFrame:Close()\
				return true\
			elseif comp==2 then\
				-- range1 lies entirely before range2\
				itemNum = prevItemNum\
				break\
			elseif comp==3 then\
				-- comp=3 range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2\
				range = combineDateRanges(range,itemText)\
				-- Delete the current item\
				o.list:DeleteItem(itemNum)\
				itemNum = prevItemNum\
				break\
			elseif comp==4 then\
				-- comp=4 range1 lies entirely inside range2\
				-- range given is subset, do nothing\
				return true\
			elseif comp==5 or comp==7 then\
				-- comp=5 range1 post overlaps range2\
				-- comp=7 range2 lies entirely inside range1\
				range = combineDateRanges(range,itemText)\
				-- Delete the current item\
				o.list:DeleteItem(itemNum)\
				itemNum = prevItemNum\
				conditionList = true	-- To condition the list to merge any overlapping ranges\
				break\
			elseif comp==6 then\
				-- range1 lies entirely after range2\
				-- Do nothing look at next item\
			else\
				return nil\
			end\
			--print(range..\">\"..tostring(comp))\
		end\
		-- itemNum contains the item after which to place item\
		if itemNum == -1 then\
			itemNum = 0\
		else \
			itemNum = itemNum + 1\
		end\
		local newItem = wx.wxListItem()\
		newItem:SetId(itemNum)\
		newItem:SetText(range)\
		o.list:InsertItem(newItem)\
		o.list:SetItem(itemNum,0,range)\
		\
		-- Condition the list here if required\
		while conditionList and o.list:GetNextItem(itemNum) ~= -1 do\
			local prevItemNum = itemNum\
			itemNum = o.list:GetNextItem(itemNum)\
			local itemText = o.list:GetItemText(itemNum)\
			-- Now compare the dateRanges\
			local comp = compareDateRanges(range,itemText)\
			if comp == 1 then\
				-- Ranges are same, delete this itemText range\
				o.list:DeleteItem(itemNum)\
				itemNum = prevItemNum\
			elseif comp==2 then\
				 -- range1 lies entirely before range2\
				 conditionList = nil\
			elseif comp==3 then\
				-- comp=3 range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2\
				range = combineDateRanges(range,itemText)\
				-- Delete the current item\
				o.list:DeleteItem(itemNum)\
				itemNum = prevItemNum\
				o.list:SetItemText(itemNum,range)\
				conditionList = nil\
			elseif comp==4 then\
				-- comp=4 range1 lies entirely inside range2\
				error(\"Code Error: This condition should never occur!\",1)\
			elseif comp==5 or comp==7 then\
				-- comp=5 range1 post overlaps range2\
				-- comp=7 range2 lies entirely inside range1\
				range = combineDateRanges(range,itemText)\
				-- Delete the current item\
				o.list:DeleteItem(itemNum)\
				itemNum = prevItemNum\
				o.list:SetItemText(itemNum,range)\
			elseif comp==6 then\
				-- range1 lies entirely after range2\
				error(\"Code Error: This condition should never occur!\",1)\
			else\
				error(\"Code Error: This condition should never occur!\",1)\
			end				\
		end		-- while conditionList and o.list:GetNextItem(itemNum) ~= -1 ends\
		o.list:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)\
    end		-- local addRange = function(range) ends\
	\
	local validateRange = function(range)\
		-- Check if the given date range is valid\
		-- Expected format is MM/DD/YYYY-MM/DD/YYYY here M and D can be single digits as well\
		local _, _, im, id, iy, fm, fd, fy = string.find(range, \"(%d+)/(%d+)/(%d%d%d%d+)%s*-%s*(%d+)/(%d+)/(%d%d%d%d+)\")\
		id = tonumber(id)\
		im = tonumber(im)\
		iy = tonumber(iy)\
		fd = tonumber(fd)\
		fm = tonumber(fm)\
		fy = tonumber(fy)\
		local ileap, fleap\
		if not(id or im or iy or fd or fm or fy) then\
			return false\
		elseif not(id > 0 and id < 32 and fd > 0 and fd < 32 and im > 0 and im < 13 and fm > 0 and fm < 13 and iy > 0 and fy > 0) then\
			return false\
		end\
		if fy < iy then\
			return false\
		end\
		if iy == fy then\
			if fm < im then\
				return false\
			end\
			if im == fm then\
				if fd < id then\
					return false\
				end\
			end\
		end \
		if iy%100 == 0 and iy%400==0 then\
			-- iy is leap year century\
			ileap = true\
		elseif iy%4 == 0 then\
			-- iy is leap year\
			ileap = true\
		end\
		if fy%100 == 0 and fy%400==0 then\
			-- fy is leap year century\
			fleap = true\
		elseif fy%4 == 0 then\
			-- fy is leap year\
			fleap = true\
		end \
		--print(id,im,iy,fd,fm,fy,ileap,fleap)\
		local validDate = function(leap,date,month)\
			local limits = {31,28,31,30,31,30,31,31,30,31,30,31}\
			if leap then\
				limits[2] = limits[2] + 1\
			end\
			if limits[month] < date then\
				return false\
			else\
				return true\
			end\
		end\
		if not validDate(ileap,id,im) then\
			return false\
		end\
		if not validDate(fleap,fd,fm) then\
			return false\
		end\
		return true\
	end\
	\
	local setRanges = function(o,ranges)\
		for i = 1,#ranges do\
			if validateRange(ranges[i]) then\
				addRange(o,ranges[i])\
			else\
				error(\"Invalid Date Range given\", 2)\
			end\
		end\
	end\
	\
	local setCheckBoxState = function(o,state)\
		o.CheckBox:SetValue(state)\
	end\
	\
	local AddPress = function(event)\
		setfenv(1,package.loaded[modname])\
		local o = objMap[event:GetId()]\
		\
		local addNewRange = function(range)\
			addRange(o,range)\
		end\
		\
		-- Create the frame to accept date range\
		SelectDateRangeCtrl(o.parent,1,addNewRange)\
	end\
	\
	local RemovePress = function(event)\
		setfenv(1,package.loaded[modname])\
		local o = objMap[event:GetId()]\
		local item = o.list:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
		local selItems = {}\
		while item ~= -1 do\
			selItems[#selItems + 1] = item	\
			item = o.list:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
		end\
		for i=#selItems,1,-1 do\
			o.list:DeleteItem(selItems[i])\
		end\
	end\
	\
	local ClearPress = function(event)\
		setfenv(1,package.loaded[modname])\
		local o = objMap[event:GetId()]\
		o.list:DeleteAllItems()	\
	end\
	\
	local ResetCtrl = function(o)\
		o.list:DeleteAllItems()\
		if o.CheckBox then\
			o.CheckBox:SetValue(false)\
		end\
	end\
	\
	local ListSel = function(event)\
		setfenv(1,package.loaded[modname])\
		local o = objMap[event:GetId()]\
        if o.list:GetSelectedItemCount() == 0 then\
			o.RemoveButton:Disable()\
        	return nil\
        end\
		o.RemoveButton:Enable(true)\
	end\
	\
	DateRangeCtrl = function(parent, noneSelection, heading)\
		-- parent is a wxPanel\
		if not parent then\
			return nil\
		end\
		local o = {ResetCtrl = ResetCtrl, getSelectedItems = getSelectedItems, setRanges = setRanges}	-- new object\
		o.parent = parent\
		-- Create the GUI elements here\
		o.Sizer = wx.wxBoxSizer(wx.wxVERTICAL)\
		\
		-- Heading\
		local label = wx.wxStaticText(parent, wx.wxID_ANY, heading, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
		o.Sizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		\
		-- List Control\
		local ID\
		ID = NewID()\
		o.list = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\
		o.list:InsertColumn(0,\"Ranges\")\
		objMap[ID] = o \
		o.list:InsertColumn(0,heading)\
		o.Sizer:Add(o.list, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		\
		-- none Selection check box\
		if noneSelection then\
			o.setCheckBoxState = setCheckBoxState\
			ID = NewID()\
			o.CheckBox = wx.wxCheckBox(parent, ID, \"None Also passes\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
			objMap[ID] = o \
			o.Sizer:Add(o.CheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
		end\
		\
		-- Add Date Range Button\
		ID = NewID()\
		o.AddButton = wx.wxButton(parent, ID, \"Add Range\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
		o.Sizer:Add(o.AddButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
		objMap[ID] = o \
\
		-- Remove Date Range Button\
		ID = NewID()\
		o.RemoveButton = wx.wxButton(parent, ID, \"Remove Range\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
		o.Sizer:Add(o.RemoveButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
		objMap[ID] = o \
		o.RemoveButton:Disable()\
		\
		-- Clear Date Ranges Button\
		ID = NewID()\
		o.ClearButton = wx.wxButton(parent, ID, \"Clear Ranges\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
		o.Sizer:Add(o.ClearButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
		objMap[ID] = o \
		\
		-- Associate Events\
		o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,AddPress)\
		o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,RemovePress)\
		o.ClearButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,ClearPress)\
\
		o.list:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED,ListSel)\
		o.list:Connect(wx.wxEVT_COMMAND_LIST_ITEM_DESELECTED,ListSel)\
		\
		return o\
	end\
	\
end		-- DateRangeCtrl ends"
__MANY2ONEFILES['TaskForm']="local requireLuaString = requireLuaString\
-----------------------------------------------------------------------------\
-- Application: Karm\
-- Purpose:     Karm application Task Entry form UI creation and handling file\
-- Author:      Milind Gupta\
-- Created:     4/11/2012\
-----------------------------------------------------------------------------\
\
local prin\
if Karm.Globals.__DEBUG then\
	prin = print\
end\
local error = error\
local tonumber = tonumber\
local tostring = tostring\
local print = prin \
local modname = ...\
local wx = wx\
local wxaui = wxaui\
local setfenv = setfenv\
local pairs = pairs\
local GUI = Karm.GUI\
local bit = bit\
local Globals = Karm.Globals\
local XMLDate2wxDateTime = Karm.Utility.XMLDate2wxDateTime\
local toXMLDate = Karm.Utility.toXMLDate\
local task2IncSchTasks = Karm.TaskObject.incSchTasks\
local getLatestScheduleDates = Karm.TaskObject.getLatestScheduleDates\
local getWorkDoneDates = Karm.TaskObject.getWorkDoneDates\
local tableToString = Karm.Utility.tableToString\
local getEmptyTask = Karm.getEmptyTask\
local copyTask = Karm.TaskObject.copy\
local collectFilterDataHier = Karm.accumulateTaskDataHier\
local togglePlanningDate = Karm.TaskObject.togglePlanningDate\
local type = type\
local checkTask = function() \
					return checkTask\
				end\
local SData = function()\
		return Karm.SporeData\
	end\
\
local CW = requireLuaString('CustomWidgets')\
\
----------------------------------------------------------\
--module(modname)\
-- NOT USING THE module KEYWORD SINCE IT DOES THIS ALSO _G[modname] = M\
local M = {}\
package.loaded[modname] = M\
setfenv(1,M)\
----------------------------------------------------------\
\
local taskData	-- To store the task data locally\
local filterData = {}\
\
local function dateRangeChangeEvent(event)\
	setfenv(1,package.loaded[modname])\
	local startDate = dateStartPick:GetValue()\
	local finDate = dateFinPick:GetValue()\
	taskTree:dateRangeChange(startDate,finDate)\
	wdTaskTree:dateRangeChange(startDate,finDate)\
	event:Skip()\
end\
\
local function dateRangeChange()\
	local startDate = dateStartPick:GetValue()\
	local finDate = dateFinPick:GetValue()\
	taskTree:dateRangeChange(startDate,finDate)\
	wdTaskTree:dateRangeChange(startDate,finDate)\
end\
\
-- Function to create the task\
-- If task is not nil then the previous schedules from that are copied over by starting with a copy of the task\
local function makeTask(task)\
	local x = tostring(task)\
	if not task then\
		error(\"Need a task object with at least a task ID\",2)\
	end\
	local newTask = copyTask(task)\
--	if task then\
--		-- Since copyTask does not replicate that\
--		newTask.DBDATA = task.DBDATA\
--	end\
	newTask.Modified = true\
	if pubPrivate:GetValue() == \"Public\" then\
		newTask.Private = false\
	else\
		newTask.Private = true\
	end \
	newTask.Title = titleBox:GetValue()\
	if newTask.Title == \"\" then\
		wx.wxMessageBox(\"The task Title cannot be blank. Please enter a title\", \"No Title Entered\",wx.wxOK + wx.wxCENTRE, frame)\
	    return nil\
	end\
	newTask.Start = toXMLDate(dateStarted:GetValue():Format(\"%m/%d/%Y\"))\
	-- newTask.TaskID = task.TaskID -- Already has task ID from copyTask\
	-- Status\
	newTask.Status = status:GetValue()\
	-- Fin\
	local todayDate = wx.wxDateTime()\
	todayDate:SetToCurrent()\
	todayDate = toXMLDate(todayDate:Format(\"%m/%d/%Y\"))\
	if task and task.Status ~= \"Done\" and newTask.Status == \"Done\" then\
		newTask.Fin = todayDate\
	elseif newTask.Status ~= \"Done\" then\
		newTask.Fin = nil\
	end\
	if priority:GetValue() ~= \"\" then\
		newTask.Priority = priority:GetValue()\
	else\
		newTask.Priority = nil\
	end\
	if DueDateEN:GetValue() then\
		newTask.Due = toXMLDate(dueDate:GetValue():Format(\"%m/%d/%Y\"))\
	else\
		newTask.Due = nil\
	end\
	-- Who List\
	local list = whoList:getAllItems()\
	if list[1] then\
		local WhoTable = {[0]=\"Who\", count = #list}\
		-- Loop through all the items in the list\
		for i = 1,#list do\
			WhoTable[i] = {ID = list[i].itemText, Status = list[i].checked}\
		end\
		newTask.Who = WhoTable\
	else\
		wx.wxMessageBox(\"The task should be assigned to someone. It cannot be blank. Please choose the people responsible.\", \"Task not assigned\",wx.wxOK + wx.wxCENTRE, frame)\
	    return nil\
	end\
	-- Access List\
	list = accList:getAllItems()\
	if list[1] then\
		local AccTable = {[0]=\"Access\", count = #list}\
		-- Loop through all the items in the Locked element Access List\
		for i = 1,#list do\
			AccTable[i] = {ID = list[i].itemText, Status = list[i].checked}\
		end\
		newTask.Access = AccTable\
	else\
		newTask.Access = nil\
	end		\
	-- Assignee List\
	list = {}\
	local itemNum = -1\
	while assigList:GetNextItem(itemNum) ~= -1 do\
		itemNum = assigList:GetNextItem(itemNum)\
		local itemText = assigList:GetItemText(itemNum)\
		list[#list + 1] = itemText\
	end\
	if list[1] then\
		local assignee = {[0]=\"Assignee\", count = #list}\
		-- Loop through all the items in the Assignee List\
		for i = 1,#list do\
			assignee[i] = {ID = list[i]}\
		end				\
		newTask.Assignee = assignee					\
	else\
		newTask.Assignee = nil\
	end		\
	-- Comments\
	if commentBox:GetValue() ~= \"\" then\
		newTask.Comments = commentBox:GetValue()\
	else \
		newTask.Comments = nil\
	end\
	-- Category\
	if Category:GetValue() ~= \"\" then\
		newTask.Cat = Category:GetValue()\
	else\
		newTask.Cat = nil\
	end\
	--SubCategory\
	if SubCategory:GetValue() ~= \"\" then \
		newTask.SubCat = SubCategory:GetValue()\
	else\
		newTask.SubCat = nil\
	end\
	-- Tags\
	list = TagsCtrl:getSelectedItems()\
	if list[1] then\
		local tagTable = {[0]=\"Tags\", count = #list}\
		-- Loop through all the items in the Tags element\
		for i = 1,#list do\
			tagTable[i] = list[i]\
		end\
		newTask.Tags = tagTable\
	else\
		newTask.Tags = nil\
	end		\
	-- Normal Schedule\
	if HoldPlanning:GetValue() then\
		newTask.Planning = taskTree.taskList[1].Planning\
	else\
		list = getLatestScheduleDates(taskTree.taskList[1],true)\
		if list then\
			local list1 = getLatestScheduleDates(newTask)\
			-- Compare the schedules\
			local same = true\
			if not list1 or #list1 ~= #list or (list1.typeSchedule ~= list.typeSchedule and \
			  not(list1.typeSchedule==\"Commit\" and list.typeSchedule == \"Revs\")) then\
				same = false\
			else\
				for i = 1,#list do\
					if list[i] ~= list1[i] then\
						same = false\
						break\
					end\
				end\
			end\
			if not same then\
				-- Add the schedule here\
				if not newTask.Schedules then\
					newTask.Schedules = {}\
				end\
				if not newTask.Schedules[list.typeSchedule] then\
					-- Schedule type does not exist so create it\
					newTask.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}\
				end\
				-- Schedule type already exists so just add it to the next index\
				local newSched = {[0]=list.typeSchedule}\
				local str = \"WD\"\
				if list.typeSchedule ~= \"Actual\" then\
					if schCommentBox:GetValue() ~= \"\" then\
						newSched.Comment = schCommentBox:GetValue()\
					end\
					newSched.Updated = todayDate\
					str = \"DP\"\
				else\
					error(\"Got Actual schedule type while processing schedule.\")\
				end\
				-- Update the period\
				newSched.Period = {[0] = \"Period\", count = #list}\
				for i = 1,#list do\
					newSched.Period[i] = {[0] = str, Date = list[i]}\
				end\
				newTask.Schedules[list.typeSchedule][list.index] = newSched\
				newTask.Schedules[list.typeSchedule].count = list.index\
			end\
		end		-- if list ends here\
		newTask.Planning = nil\
	end		-- if HoldPlanning.GetValue() then ends\
	-- Work done Schedule\
	list = getLatestScheduleDates(wdTaskTree.taskList[1],true)\
	if list then\
		local list1 = getWorkDoneDates(newTask)\
		-- Compare the schedules\
		local same = true\
		if not list1 or #list1 ~= #list then\
			same = false\
		else\
			for i = 1,#list do\
				if list[i] ~= list1[i] then\
					same = false\
					break\
				end\
			end\
		end\
		if not same then\
			-- Add the schedule here\
			if not newTask.Schedules then\
				newTask.Schedules = {}\
			end\
			if not newTask.Schedules[list.typeSchedule] then\
				-- Schedule type does not exist so create it\
				newTask.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}\
			end\
			-- Schedule type already exists so just add it to the next index\
			local newSched = {[0]=list.typeSchedule, Updated = todayDate}\
			local str = \"WD\"\
			-- Update the period\
			newSched.Period = {[0] = \"Period\", count = #list}\
			for i = 1,#list do\
				newSched.Period[i] = wdTaskTree.taskList[1].Planning.Period[i]\
			end\
			newTask.Schedules[list.typeSchedule][list.index] = newSched\
			newTask.Schedules[list.typeSchedule].count = list.index\
		end\
	end		-- if list ends here\
--	print(tableToString(list))\
--	print(tableToString(newTask))\
	local chkTask = checkTask()\
	if type(chkTask) == \"function\" then\
		local err,msg = chkTask(newTask)\
		if not err then\
			msg = msg or \"Error in the task. Please review.\"\
			wx.wxMessageBox(msg, \"Task Error\",wx.wxOK + wx.wxCENTRE, frame)\
			return nil\
		end\
	end\
	return newTask\
end\
\
function taskFormActivate(parent, callBack, task)\
	local SporeData = SData()\
	-- Accumulate Filter Data across all spores\
	-- Loop through all the spores\
	for k,v in pairs(SporeData) do\
		if k~=0 then\
			collectFilterDataHier(filterData,v)\
		end		-- if k~=0 then ends\
	end		-- for k,v in pairs(SporeData) do ends\
	frame = wx.wxFrame(parent, wx.wxID_ANY, \"Task Form\", wx.wxDefaultPosition,\
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)\
\
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
		-- Create the tab book\
		MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)\
		-- Basic Task Info\
		TInfo = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\
				local sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
				local textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Title:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				if task and task.Title then\
					titleBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, task.Title, wx.wxDefaultPosition, wx.wxDefaultSize)\
				else\
					titleBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize)\
				end				\
				sizer2:Add(titleBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					-- Start Date\
					local sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Start Date:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					if task and task.Start then\
						dateStarted = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,XMLDate2wxDateTime(task.Start), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\
					else\
						dateStarted = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\
					end					\
					sizer3:Add(dateStarted, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
					-- Due Date\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Due Date:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					local sizer4 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					DueDateEN = wx.wxCheckBox(TInfo, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
					DueDateEN:SetValue(false)\
					sizer4:Add(DueDateEN, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
					if task and task.Due then\
						dueDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,XMLDate2wxDateTime(task.Due), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\
					else\
						dueDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\
					end	\
					-- dueDate:SetRange(XMLDate2wxDateTime(\"1900-01-01\"),XMLDate2wxDateTime(\"3000-01-01\"))					\
					sizer4:Add(dueDate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					sizer3:Add(sizer4,1,bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
					-- Priority\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Priority:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					local list = {\"\"}\
					for i = 1,#Globals.PriorityList do\
						list[i+1] = Globals.PriorityList[i]\
					end\
					if task and task.Priority then\
						priority = wx.wxComboBox(TInfo, wx.wxID_ANY,task.Priority, wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)\
					else\
						priority = wx.wxComboBox(TInfo, wx.wxID_ANY,\"\", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)\
					end\
					sizer3:Add(priority, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
\
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
\
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					-- Private/Public\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Private/Public:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					list = {\"Public\",\"Private\"}\
					if task and task.Private then\
						pubPrivate = wx.wxComboBox(TInfo, wx.wxID_ANY,\"Private\", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)\
					else\
						pubPrivate = wx.wxComboBox(TInfo, wx.wxID_ANY,\"Public\", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)\
					end\
					sizer3:Add(pubPrivate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
					-- Status\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Status:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					if task and task.Status then\
						status = wx.wxComboBox(TInfo, wx.wxID_ANY,task.Status, wx.wxDefaultPosition, wx.wxDefaultSize, Globals.StatusList, wx.wxCB_READONLY)\
					else\
						status = wx.wxComboBox(TInfo, wx.wxID_ANY,Globals.StatusList[1], wx.wxDefaultPosition, wx.wxDefaultSize, Globals.StatusList, wx.wxCB_READONLY)\
					end					\
					sizer3:Add(status, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
					sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
				-- Comment\
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)\
				textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Comment:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				if task and task.Comments then\
					commentBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, task.Comments, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)\
				else\
					commentBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)\
				end\
				sizer2:Add(commentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
\
				\
				TInfo:SetSizer(sizer1)\
			sizer1:SetSizeHints(TInfo)\
		MainBook:AddPage(TInfo, \"Basic Info\")				\
\
		-- Classification Page\
		TClass = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\
\
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
					textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, \"Category:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					list = {\"\"}\
					for i = 1,#Globals.Categories do\
						list[i+1] = Globals.Categories[i]\
					end\
					if task and task.Cat then\
						Category = wx.wxComboBox(TClass, wx.wxID_ANY,task.Cat, wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)\
					else\
						Category = wx.wxComboBox(TClass, wx.wxID_ANY,list[1], wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)\
					end					\
					sizer3:Add(Category, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
					textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, \"Sub-Category:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					list = {\"\"}\
					for i = 1,#Globals.SubCategories do\
						list[i+1] = Globals.SubCategories[i]\
					end\
					if task and task.SubCat then\
						SubCategory = wx.wxComboBox(TClass, wx.wxID_ANY,task.SubCat, wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)\
					else\
						SubCategory = wx.wxComboBox(TClass, wx.wxID_ANY,list[1], wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)\
					end					\
					sizer3:Add(SubCategory, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
\
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
\
				textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, \"Tags:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\
				sizer1:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				TagsCtrl = CW.MultiSelectCtrl(TClass,filterData.Tags,nil,false,true)\
				if task and task.Tags then\
					TagsCtrl:AddSelListData(task.Tags)\
				end\
				sizer1:Add(TagsCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
				TClass:SetSizer(sizer1)\
			sizer1:SetSizeHints(TClass)\
		MainBook:AddPage(TClass, \"Classification\")				\
\
		-- People Page\
		TPeople = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)\
				-- Resources\
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, \"People:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				resourceList = wx.wxListCtrl(TPeople, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\
				resourceList:InsertColumn(0,\"Options\")\
				-- Populate the resources\
				if not Globals.Resources or #Globals.Resources == 0 then\
					wx.wxMessageBox(\"There are no people in the Globals.Resources setting. Please add a list of people to which task can be assigned\", \"No People found\",wx.wxOK + wx.wxCENTRE, frame) \
					frame:Close()\
					callBack(nil)\
					return\
				end\
				\
				for i = 1,#Globals.Resources do\
					CW.InsertItem(resourceList,Globals.Resources[i])\
				end\
				CW.InsertItem(resourceList,Globals.User)\
				sizer2:Add(resourceList, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				-- Selection boxes and buttons\
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)\
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\
				AddWhoButton = wx.wxButton(TPeople, wx.wxID_ANY, \">\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				sizer4:Add(AddWhoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				RemoveWhoButton = wx.wxButton(TPeople, wx.wxID_ANY, \"X\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				sizer4:Add(RemoveWhoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, \"Who: (Checked=InActive)\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				whoList = CW.CheckListCtrl(TPeople,false,\"Inactive\",\"Active\")\
				if task and task.Who then\
					for i = 1,#task.Who do\
						local id = task.Who[i].ID\
						if task.Who[i].Status == \"Active\" then\
							whoList:InsertItem(id)\
						else\
							whoList:InsertItem(id,true)\
						end\
					end\
				end\
				sizer4:Add(whoList.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\
				AddAccButton = wx.wxButton(TPeople, wx.wxID_ANY, \">\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				sizer4:Add(AddAccButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				RemoveAccButton = wx.wxButton(TPeople, wx.wxID_ANY, \"X\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				sizer4:Add(RemoveAccButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, \"Access: (Checked=Read/Write)\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				accList = CW.CheckListCtrl(TPeople,false,\"Read/Write\",\"Read Only\")\
				if task and task.Access then\
					for i = 1,#task.Access do\
						local id = task.Access[i].ID\
						if task.Access[i].Status == \"Read/Write\" then\
							accList:InsertItem(id,true)\
						else\
							accList:InsertItem(id)\
						end\
					end\
				end				\
				sizer4:Add(accList.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
\
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\
				AddAssigButton = wx.wxButton(TPeople, wx.wxID_ANY, \">\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				sizer4:Add(AddAssigButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				RemoveAssigButton = wx.wxButton(TPeople, wx.wxID_ANY, \"X\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				sizer4:Add(RemoveAssigButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, \"Assignee:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				assigList = wx.wxListCtrl(TPeople, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\
				assigList:InsertColumn(0,\"Assignees\")\
				if task and task.Assignee then\
					for i = 1,#task.Assignee do\
						CW.InsertItem(assigList,task.Assignee[i].ID)\
					end\
				end\
				sizer4:Add(assigList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
				TPeople:SetSizer(sizer1)\
			sizer1:SetSizeHints(TPeople)\
		MainBook:AddPage(TPeople, \"People\")				\
\
		-- Schedule Page\
		TSch = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					dateStartPick = wx.wxDatePickerCtrl(TSch, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\
					startDate = dateStartPick:GetValue()\
					local month = wx.wxDateSpan(0,1,0,0)\
					dateFinPick = wx.wxDatePickerCtrl(TSch, wx.wxID_ANY,startDate:Add(month), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\
					sizer2:Add(dateStartPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, wx.wxALIGN_CENTER_VERTICAL), 1)\
					sizer2:Add(dateFinPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 	wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				local staticBoxSizer = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, TSch, \"Work Done\")\
					wdTaskTree = GUI.newTreeGantt(TSch,true)\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
					sizer3:Add(wdTaskTree.horSplitWin, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
					sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\
					local wdDateLabel = wx.wxStaticText(TSch, wx.wxID_ANY, \"Date: XX/XX/XXXX\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\
					sizer4:Add(wdDateLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					local wdHourLabel = wx.wxStaticText(TSch, wx.wxID_ANY, \"Hours: \", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\
					sizer4:Add(wdHourLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					sizer2:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
					local wdCommentLabel = wx.wxStaticText(TSch, wx.wxID_ANY, \"Comment: \", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					sizer2:Add(wdCommentLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					local wdCommentBox = wx.wxTextCtrl(TSch, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE + wx.wxTE_READONLY)\
					sizer2:Add(wdCommentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
					sizer3:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
					staticBoxSizer:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				sizer1:Add(staticBoxSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
				staticBoxSizer = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, TSch, \"Schedules\")\
				sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\
				\
				taskTree = GUI.newTreeGantt(TSch,true)\
				sizer3:Add(taskTree.horSplitWin, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				dateRangeChange()\
				taskTree:layout()\
				wdTaskTree:layout()\
				local localTask1, localTask2\
				if not task.Title then\
					localTask1 = getEmptyTask()\
					localTask2 = getEmptyTask()\
				else\
					localTask1 = copyTask(task)\
					localTask2 = copyTask(task)\
				end\
				-- Create the 1st row for the task\
				localTask1.Planning = nil	-- Since we will use this task for Work Done Entry and Work done never maintains the Planning\
			    wdTaskTree:Clear()\
			    wdTaskTree:AddNode{Key=localTask1.TaskID, Text = localTask1.Title, Task = localTask1}\
			    wdTaskTree.Nodes[localTask1.TaskID].ForeColor = GUI.nodeForeColor\
			    taskTree:Clear()\
			    taskTree:AddNode{Key=localTask2.TaskID, Text = localTask2.Title, Task = localTask2}\
			    taskTree.Nodes[localTask2.TaskID].ForeColor = GUI.nodeForeColor\
			    local prevKey = localTask1.TaskID\
				-- Get list of mock tasks with incremental schedule\
				if task and task.Schedules then\
					local taskList = task2IncSchTasks(task)\
					-- Now add these tasks\
					for i = 1,#taskList do\
						taskList[i].Planning = nil	-- To make sure that a task already having Planning does not propagate that in successive schedules\
		            	taskTree:AddNode{Relative=prevKey, Relation=\"Next Sibling\", Key=taskList[i].TaskID, Text=taskList[i].Title, Task = taskList[i]}\
		            	taskTree.Nodes[taskList[i].TaskID].ForeColor = GUI.nodeForeColor\
		            	prevKey = taskList[i].TaskID\
		            end\
				end\
				-- Enable planning mode for the task\
				taskTree:enablePlanningMode({localTask2},\"NORMAL\")\
				wdTaskTree:enablePlanningMode({localTask1},\"WORKDONE\")\
				-- Add the comment box\
				sizer4 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
				textLabel = wx.wxStaticText(TSch, wx.wxID_ANY, \"Comment:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\
				sizer4:Add(textLabel, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				HoldPlanning = wx.wxCheckBox(TSch, wx.wxID_ANY, \"Hold Planning\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				HoldPlanning:SetValue(false)\
				sizer4:Add(HoldPlanning, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				schCommentBox = wx.wxTextCtrl(TSch, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize)\
				sizer3:Add(schCommentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
				staticBoxSizer:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				sizer1:Add(staticBoxSizer, 2, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\
				\
				TSch:SetSizer(sizer1)\
			sizer1:SetSizeHints(TSch)\
		MainBook:AddPage(TSch, \"Schedules\")	\
		\
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
	CancelButton = wx.wxButton(frame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
	sizer1:Add(CancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	DoneButton = wx.wxButton(frame, wx.wxID_ANY, \"Done\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
	sizer1:Add(DoneButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	MainSizer:Add(sizer1, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
	frame:SetSizer(MainSizer)\
\
	-- Event handler for the Work Done elements\
	local workDoneHourCommentEntry = function(task,row,col,date)\
		-- First check whether the date is in the schedule\
		local exist = false\
		local prevHours, prevComment\
		if localTask1.Planning then\
			for i = 1,#localTask1.Planning.Period do\
				if date == localTask1.Planning.Period[i].Date then\
					prevHours = localTask1.Planning.Period[i].Hours or \"\"\
					prevComment = localTask1.Planning.Period[i].Comment or \"\"\
					exist = true\
					break\
				end\
			end\
		end\
		if exist then\
			local wdFrame = wx.wxFrame(frame, wx.wxID_ANY, \"Work Done Details for date \"..date, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxDEFAULT_FRAME_STYLE)\
			local wdSizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\
				-- Data entry UI\
				local wdSizer2 = wx.wxBoxSizer(wx.wxVERTICAL)\
					local wdSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					wdTextLabel = wx.wxStaticText(wdFrame, wx.wxID_ANY, \"Hours:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\
					wdSizer3:Add(wdTextLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					local wdList = {\"1\", \"2\",\"3\",\"4\",\"5\",\"6\",\"7\",\"8\",\"9\",\"10\"}\
					local wdHours = wx.wxComboBox(wdFrame, wx.wxID_ANY,prevHours, wx.wxDefaultPosition, wx.wxDefaultSize,wdList)\
					wdSizer3:Add(wdHours, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					wdSizer2:Add(wdSizer3, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
					wdSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					wdTextLabel = wx.wxStaticText(wdFrame, wx.wxID_ANY, \"Comment:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
					wdSizer3:Add(wdTextLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
					wdSizer2:Add(wdSizer3, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
					local w = 0.5*GUI.initFrameW\
					local l = 0.5*GUI.initFrameH\
					w = w - w%1\
					l = l - l%1\
					local wdComment = wx.wxTextCtrl(wdFrame, wx.wxID_ANY, prevComment, wx.wxDefaultPosition, wx.wxSize(w, l), wx.wxTE_MULTILINE)\
					wdSizer2:Add(wdComment, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				wdSizer1:Add(wdSizer2, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				-- Buttons\
				wdSizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					local wdCancelButton = wx.wxButton(wdFrame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
					wdSizer2:Add(wdCancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
					local wdDoneButton = wx.wxButton(wdFrame, wx.wxID_ANY, \"Done\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
					wdSizer2:Add(wdDoneButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				wdSizer1:Add(wdSizer2, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			wdFrame:SetSizer(wdSizer1)\
			wdSizer1:SetSizeHints(wdFrame)\
			wdCancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
				function (event)\
					wdFrame:Close()\
				end\
			)\
			wdDoneButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
				function (event)\
					setfenv(1,package.loaded[modname])\
					local hours = wdHours:GetValue()\
					local comment = wdComment:GetValue()\
					if tonumber(hours) then\
						hours = tostring(tonumber(hours))\
					else\
						hours = \"\"\
					end\
					if hours ~= \"\" or comment ~= \"\" then\
						-- Add the hours and Comment information to the task here\
						for i = 1,#localTask1.Planning.Period do\
							if localTask1.Planning.Period[i].Date == date then\
								if hours ~= \"\" then\
									localTask1.Planning.Period[i].Hours = hours\
								end\
								if comment ~= \"\" then\
									localTask1.Planning.Period[i].Comment = comment\
								end\
								break\
							end\
						end\
						-- Update the hours and comment box\
						wdDateLabel:SetLabel(\"Date: \"..date:sub(-5,-4)..\"/\"..date:sub(-2,-1)..\"/\"..date:sub(1,4))\
						wdHourLabel:SetLabel(\"Hours: \"..hours)\
						wdCommentBox:SetValue(comment)\
					end		-- if hours ~= \"\" or comment ~= \"\" then ends\
					wdFrame:Close()\
				end\
			)\
		    wdFrame:Layout() -- help sizing the windows before being shown\
		    wdFrame:Show(true)\
		end	-- if exist then ends		\
	end\
	\
	local prevDate, wdPlanning\
	wdPlanning = {Planning = {Type = \"Actual\", index = 1}}\
	\
	local function updateHoursComment(task,row,col,date)\
		if not prevDate then\
			prevDate = date\
		end\
		-- First check whether the date is in the schedule\
		local exist = false\
		local existwd = false\
		local perNum, wdNum\
		if localTask1.Planning then\
			for i = 1,#localTask1.Planning.Period do\
				if date == localTask1.Planning.Period[i].Date then\
					perNum = i\
					exist = true\
					break\
				end\
			end\
		end\
		if wdPlanning.Planning.Period then\
			for i = 1,#wdPlanning.Planning.Period do\
				if date == wdPlanning.Planning.Period[i].Date then\
					wdNum = i\
					existwd = true\
					break\
				end\
			end\
		end\
		\
		if exist then\
			if not existwd then\
				-- Add it to wdPlanning\
				if not wdPlanning.Planning.Period then\
					wdPlanning.Planning.Period = {}\
				end\
				wdPlanning.Planning.Period[#wdPlanning.Planning.Period + 1] = localTask1.Planning.Period[perNum]\
			end\
		else\
			if existwd then\
				if prevDate ~= date then\
					-- Add it back in the task\
					togglePlanningDate(localTask1,date,\"WORKDONE\")\
					for i = 1,#localTask1.Planning.Period do\
						if localTask1.Planning.Period[i].Date == date then\
							localTask1.Planning.Period[i].Hours = wdPlanning.Planning.Period[wdNum].Hours\
							localTask1.Planning.Period[i].Comment = wdPlanning.Planning.Period[wdNum].Comment\
							break\
						end\
					end\
					-- Update GUI\
					wdTaskTree:RefreshNode(localTask1)\
				else\
					-- Remove it from wdPlanning\
					for i = wdNum,#wdPlanning.Planning.Period - 1 do\
						wdPlanning.Planning.Period[i] = wdPlanning.Planning.Period[i+1]\
					end\
					wdPlanning.Planning.Period[#wdPlanning.Planning.Period] = nil\
				end\
			end\
		end\
		prevDate = date\
		local hours, comment\
		-- Extract the hours and comments\
		if localTask1.Planning then\
			for i = 1,#localTask1.Planning.Period do\
				if date == localTask1.Planning.Period[i].Date then\
					hours = localTask1.Planning.Period[i].Hours\
					comment = localTask1.Planning.Period[i].Comment\
					break\
				end\
			end\
		end\
		-- Update the hours and comment box\
		wdDateLabel:SetLabel(\"Date: \"..date:sub(-5,-4)..\"/\"..date:sub(-2,-1)..\"/\"..date:sub(1,4))\
		if hours then\
			wdHourLabel:SetLabel(\"Hours: \"..hours)\
		else\
			wdHourLabel:SetLabel(\"Hours: \")\
		end\
		if comment then\
			wdCommentBox:SetValue(comment)\
		else\
			wdCommentBox:SetValue(\"\")\
		end		\
	end\
	\
	wdTaskTree:associateEventFunc({ganttCellDblClickCallBack = workDoneHourCommentEntry, ganttCellClickCallBack = updateHoursComment})\
	-- Connect event handlers to the buttons\
	RemoveAccButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			local item = accList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
			while item ~= -1 do\
				accList.List:DeleteItem(item)			\
				item = accList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
			end\
		end\
	)\
\
	RemoveAssigButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			local item = assigList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
			while item ~= -1 do\
				assigList:DeleteItem(item)			\
				item = assigList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
			end\
		end\
	)\
\
	RemoveWhoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			local selItems = {}\
			local item = whoList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
			while item ~= -1 do\
				whoList.List:DeleteItem(item)\
				item = whoList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
			end\
		end\
	)\
\
	AddAccButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
			while item ~= -1 do\
				local itemText = resourceList:GetItemText(item)\
				accList:InsertItem(itemText)			\
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
			end\
		end\
	)\
	\
	AddAssigButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
			while item ~= -1 do\
				local itemText = resourceList:GetItemText(item)\
				CW.InsertItem(assigList,itemText)		\
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
			end\
		end\
	)\
\
	AddWhoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
			while item ~= -1 do\
				local itemText = resourceList:GetItemText(item)\
				whoList:InsertItem(itemText)			\
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\
			end\
		end\
	)\
\
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function (event)\
			setfenv(1,package.loaded[modname])		\
			frame:Close()\
			callBack(nil)\
		end\
	)\
	\
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,\
		function (event)\
			setfenv(1,package.loaded[modname])		\
			event:Skip()\
			callBack(nil)\
		end\
	)\
\
	DoneButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			local newTask = makeTask(task)\
			if newTask then\
				callBack(newTask)\
				frame:Close()\
			end\
		end		\
	)\
	\
	DueDateEN:Connect(wx.wxEVT_COMMAND_CHECKBOX_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			if DueDateEN:GetValue() then\
				dueDate:Enable(true)\
			else\
				dueDate:Disable()\
			end\
		end\
	)\
	\
	-- Date Picker Events\
	dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,dateRangeChangeEvent)\
	dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,dateRangeChangeEvent)\
	\
\
    frame:Layout() -- help sizing the windows before being shown\
    frame:Show(true)\
\
end	-- function taskFormActivate(parent, callBack)"
__MANY2ONEFILES['Filter']="-- Data structure to store the Global Filter Criteria\
Karm.Filter = {}\
Karm.FilterObject = {}\
-- Table to store the Core values\
Karm.Core.FilterObject = {}\
--[[\
do\
	local KarmMeta = {__metatable = \"Hidden, Do not change!\"}\
	KarmMeta.__newindex = function(tab,key,val)\
		print(\"I am here\")\
		if Karm.FilterObject.key and not Karm.Core.FilterObject.key then\
			Karm.Core.FilterObject.key = Karm.FilterObject.key\
			print(\"Set\")\
		end\
		rawset(Karm.FilterObject,key,val)\
	end\
	setmetatable(Karm.FilterObject,KarmMeta)\
end\
]]\
\
-- Function to create a text summary of the Filter\
function Karm.FilterObject.getSummary(filter)\
	local filterSummary = \"\"\
	-- Tasks\
	if filter.Tasks then\
		-- Get the task name\
		for i=1,#filter.Tasks do\
			if i>1 then\
				filterSummary = filterSummary..\"\\n\"\
			else\
				filterSummary = \"TASKS: \"\
			end\
			filterSummary = filterSummary..filter.Tasks[i].Title\
			if filter.Tasks[i].Children then\
				filterSummary = filterSummary..\" and Children\"\
			end\
		end\
		filterSummary = filterSummary..\"\\n\"\
	end\
	-- Who\
	if filter.Who then\
		filterSummary = filterSummary..\"PEOPLE: \"..filter.Who..\"\\n\"\
	end\
	-- Start Date\
	if filter.Start then\
		filterSummary = filterSummary..\"START DATE: \"..filter.Start..\"\\n\"\
	end\
	-- Finish Date\
	if filter.Fin then\
		filterSummary = filterSummary..\"FINISH DATE: \"..filter.Fin..\"\\n\"\
	end\
	-- Access IDs\
	if filter.Access then\
		filterSummary = filterSummary..\"ACCESS: \"..filter.Access..\"\\n\"\
	end\
	-- Status\
	if filter.Status then\
		filterSummary = filterSummary..\"STATUS: \"..filter.Status..\"\\n\"\
	end\
	-- Priority\
	if filter.Priority then\
		filterSummary = filterSummary..\"PRIORITY: \"..filter.Priority..\"\\n\"\
	end\
	-- Due Date\
	if filter.Due then\
		filterSummary = filterSummary..\"DUE DATE: \"..filter.Due..\"\\n\"\
	end\
	-- Category\
	if filter.Cat then\
		filterSummary = filterSummary..\"CATEGORY: \"..filter.Cat..\"\\n\"\
	end\
	-- Sub-Category\
	if filter.SubCat then\
		filterSummary = filterSummary..\"SUB-CATEGORY: \"..filter.SubCat..\"\\n\"\
	end\
	-- Tags\
	if filter.Tags then\
		filterSummary = filterSummary..\"TAGS: \"..filter.Tags..\"\\n\"\
	end\
	-- Schedules\
	if filter.Schedules then\
		filterSummary = filterSummary..\"SCHEDULES: \"..filter.Schedules..\"\\n\"\
	end\
	if filter.Script then\
		filterSummary = filterSummary..\"CUSTOM SCRIPT APPLIED\"..\"\\n\"\
	end\
	if filterSummary == \"\" then\
		filterSummary = \"No Filtering\"\
	end\
	return filterSummary\
end\
\
-- Function to filter out tasks from the task hierarchy\
function Karm.FilterObject.applyFilterHier(filter, taskHier)\
	local hier = taskHier\
	local returnList = {count = 0}\
	local data = {returnList = returnList, filter = filter}\
	for i = 1,#hier do\
		data = Karm.TaskObject.applyFuncHier(hier[i],function(task,data)\
							  	local passed = Karm.FilterObject.validateTask(data.filter,task)\
							  	if passed then\
							  		data.returnList.count = data.returnList.count + 1\
							  		data.returnList[data.returnList.count] = task\
							  	end\
							  	return data\
							  end, data\
		)\
	end\
	return data.returnList\
end\
\
-- Old Version\
--function Karm.FilterObject.applyFilterHier(filter, taskHier)\
--	local hier = taskHier\
--	local hierCount = {}\
--	local returnList = {count = 0}\
----[[	-- Reset the hierarchy if not already done so\
--	while hier.parent do\
--		hier = hier.parent\
--	end]]\
--	-- Traverse the task hierarchy here\
--	hierCount[hier] = 0\
--	while hierCount[hier] < #hier or hier.parent do\
--		if not(hierCount[hier] < #hier) then\
--			if hier == taskHier then\
--				-- Do not go above the passed task\
--				break\
--			end \
--			hier = hier.parent\
--		else\
--			-- Increment the counter\
--			hierCount[hier] = hierCount[hier] + 1\
--			local passed = Karm.FilterObject.validateTask(filter,hier[hierCount[hier]])\
--			if passed then\
--				returnList.count = returnList.count + 1\
--				returnList[returnList.count] = hier[hierCount[hier]]\
--			end\
--			if hier[hierCount[hier]].SubTasks then\
--				-- This task has children so go deeper in the hierarchy\
--				hier = hier[hierCount[hier]].SubTasks\
--				hierCount[hier] = 0\
--			end\
--		end\
--	end		-- while hierCount[hier] < #hier or hier.parent do ends here\
--	return returnList\
--end\
\
-- Function to filter out tasks from a list of tasks\
function Karm.FilterObject.applyFilterList(filter, taskList)\
	local returnList = {count = 0}\
	for i=1,#taskList do\
		local passed = Karm.FilterObject.validateTask(filter,taskList[i])\
		if passed then\
			returnList.count = returnList.count + 1\
			returnList[returnList.count] = taskList[i]\
		end\
	end\
	return returnList\
end\
\
--[[ The Task Filter should filter the following:\
\
1. Tasks - Particular tasks with or without its children - This is a table with each element (starting from 1) has a Specified Task ID, Task Title, with 'children' flag. If TaskID = Karm.Globals.ROOTKEY..(Spore File name) then the whole spore will pass the filter\
2. Who - People responsible for the task (Boolean) - Boolean string with people IDs with their status in single quotes \"'milind.gupta,A' or 'aryajur,A' and not('milind_gupta,A' or 'milind0x,I')\" - if status not present then taken to be A (Active) \
3. Date_Started - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by ,\
4. Date_Finished - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by , Karm.Globals.NoDateStr means no date also passes\
5. AccessIDs - Boolean expression of IDs and their access permission - \"'milind.gupta,R' or 'aryajur,W' and not('milind_gupta,W' or 'milind0x,W')\", Karm.Globals.NoAccessIDStr means tasks without an Access ID list also pass\
6. Status - Member of given list of status types - List of status types separated by commas\
7. Priority - Member of given list of priority types - List of priority numbers separated by commas -\"1,2,3\", Karm.Globals.NoPriStr means no priority also passes\
8. Date_Due - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by , Karm.Globals.NoDateStr means no date also passes\
9. Category - Member of given list of Categories - List of categories separated by commas, Karm.Globals.NoCatStr means tasks without any category also pass\
10. Sub-Category - Member of given list of Sub-Categories - List of sub-categories separated by commas, Karm.Globals.NoSubCatStr means tasks without any sub-category also pass\
11. Tags - Boolean expression of Tags - \"'Technical' or 'Electronics'\" - Tags allow alphanumeric characters spaces and underscores - For no TAG the tag would be Karm.Globals.NoDateStr\
12. Schedules - Type of matching - Fully Contained or any overlap with the given ranges\
		Type of Schedule - Estimate, Committed, Revisions (L=Latest or the number of revision) or Actual or Latest (means the latest schedule, note Actual is only latest if task is marked DONE)\
		Boolean expression different schedule criterias together \
		\"'Full,Estimate(L),12/1/2011-12/5/2011,12/10/2011-1/2/2012' and 'Overlap,Revision(L),12/1/2011-1/2/2012' or 'Full,Estimate(L),'..Karm.Globals.NoDateStr\"\
		Karm.Globals.NoDateStr signifies no schedule for the type of schedule the type of matching is ignored in this case\
13. Script - The custom user script. task is passed in task variable. Executes in the Karm.Globals.safeenv environment. Final result (true or false) is present in the result variable\
]]\
\
-- Function to validate a given task\
function Karm.FilterObject.validateTask(filter, task)\
	if not filter then\
		return true\
	end\
	-- Check if task ID passes\
	if filter.Tasks then\
		local matched = false\
		for i = 1,#filter.Tasks do\
			if string.sub(filter.Tasks[i].TaskID,1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then\
				-- A whole spore is marked check if this task belongs to that spore\
				-- Check if this is the spore of the task\
				if string.sub(filter.Tasks[i].TaskID,#Karm.Globals.ROOTKEY+1,-1) == task.SporeFile then\
					if not filter.Tasks[i].Children then\
						return false\
					end\
					matched = true\
					break\
				end\
			else  \
				-- Check if the task ID matches\
				if filter.Tasks[i].Children then\
					-- Children are allowed\
					if filter.Tasks[i].TaskID == task.TaskID or \
					  filter.Tasks[i].TaskID == string.sub(task.TaskID,1,#filter.Tasks[i].TaskID) then\
						matched = true\
						break\
					end\
				else\
					if filter.Tasks[i].TaskID == task.TaskID then\
						matched = true\
						break\
					end\
				end\
			end		-- if filter.Tasks.TaskID == Karm.Globals.ROOTKEY..\"S\" then ends\
		end	-- for 1,#filter.Tasks ends here\
		if not matched then\
			return false\
		end\
	end\
	-- Check if Who passes\
	if filter.Who then\
		local pattern = \"%'([%w%.%_%,]+)%'\"\
		local whoStr = filter.Who\
		for id in string.gmatch(filter.Who,pattern) do\
			-- Check if the Status is given\
			local idc = id\
			local st = string.find(idc,\",\")\
			local stat\
			if st then\
				-- Status exists, extract it here\
				stat = string.sub(idc,st+1,-1)\
				idc = string.sub(idc,1,st-1)\
			else\
				stat = \"A\"\
			end\
			-- Check if the id exists in the task\
			local result = false\
			for i = 1,#task.Who do\
				if task.Who[i].ID == idc then\
					if stat == \"A\" and string.upper(task.Who[i].Status) == \"ACTIVE\" then\
						result = true\
						break\
					end\
					if stat ==\"I\" and string.upper(task.Who[i].Status) ==\"INACTIVE\" then\
						result = true\
						break\
					end\
					result = false\
					break\
				end		-- if task.Who[i].ID == idc then ends\
			end		-- for i = 1,#task.Who ends\
			whoStr = string.gsub(whoStr,\"'\"..id..\"'\",tostring(result))\
		end		-- for id in string.gmatch(filter.Who,pattern) do ends\
		-- Check if the boolean passes\
		if not loadstring(\"return \"..whoStr)() then\
			return false\
		end\
	end		-- if filter.Who then ends\
	\
	-- Check if Date Started Passes\
	if filter.Start then\
		-- Trim the string from leading and trailing spaces\
		local strtStr = string.match(filter.Start,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(strtStr,-1,-1)~=\",\" then\
			strtStr = strtStr .. \",\"\
		end\
		local matched = false\
		for range in string.gmatch(strtStr,\"(.-),\") do\
			-- See if this is a range or a single date\
			local strt,stp = string.match(range,\"(.-)%-(.*)\")\
			if not strt then\
				-- its not a range\
				strt = range\
				stp = range\
			end\
			strt = Karm.Utility.toXMLDate(strt)\
			stp = Karm.Utility.toXMLDate(stp)\
			local taskDate = task.Start\
			if strt <= taskDate and taskDate <=stp then\
				matched = true\
				break\
			end\
		end\
		if not matched then\
			return false\
		end\
	end\
\
	-- Check if Date Finished Passes\
	if filter.Fin then\
		-- Trim the string from leading and trailing spaces\
		local finStr = string.match(filter.Fin,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(finStr,-1,-1)~=\",\" then\
			finStr = finStr .. \",\"\
		end\
		local matched = false\
		for range in string.gmatch(finStr,\"(.-),\") do\
			-- Check if this is Karm.Globals.NoDateStr\
			if range == Karm.Globals.NoDateStr and not task.Fin then\
				matched = true\
				break\
			end\
			-- See if this is a range or a single date\
			local strt,stp = string.match(range,\"(.-)%-(.*)\")\
			if not strt then\
				-- its not a range\
				strt = range\
				stp = range\
			end\
			strt = Karm.Utility.toXMLDate(strt)\
			stp = Karm.Utility.toXMLDate(stp)\
			if task.Fin then\
				if strt <= task.Fin and task.Fin <=stp then\
					matched = true\
					break\
				end\
			end\
		end\
		if not matched then\
			return false\
		end\
	end\
\
	-- Check if Access IDs pass\
	if filter.Access then\
		local pattern = Karm.Globals.UserIDPattern\
		local accStr = filter.Access\
		for id in string.gmatch(filter.Access,pattern) do\
			local result = false\
			if id == Karm.Globals.NoAccessIDStr and not task.Access then\
				result = true\
			else\
				-- Extract the permission character\
				local idc = id\
				local st = string.find(idc,\",\")\
				local perm\
	\
				perm = string.sub(idc,st+1,-1)\
				idc = string.sub(idc,1,st-1)\
				\
				-- Check if the id exists in the task\
				if task.Access then\
					for i = 1,#task.Access do\
						if task.Access[i].ID == idc then\
							if string.upper(perm) == \"R\" and string.upper(task.Access[i].Status) == \"READ ONLY\" then\
								result = true\
								break\
							end\
							if string.upper(perm) ==\"W\" and string.upper(task.Access[i].Status) ==\"READ/WRITE\" then\
								result = true\
								break\
							end\
							result = false\
							break\
						end		-- if task.Access[i].ID == idc then ends\
					end		-- for i = 1,#task.Access do ends\
				end\
				if not result then\
					-- Check for Read/Write access does the ID exist in the Who table\
					if string.upper(perm) == \"W\" then\
						for i = 1,#task.Who do\
							if task.Who[i].ID == idc then\
								if string.upper(task.Who[i].Status) == \"ACTIVE\" then\
									result = true\
								end\
								break\
							end\
						end		-- for i = 1,#task.Who do ends\
					end		-- if string.upper(perm) == \"W\" then ends\
				end		-- if not result then ends\
			end		-- if id == Karm.Globals.NoAccessIDStr and not task.Access then ends\
			accStr = string.gsub(accStr,\"'\"..id..\"'\",tostring(result))\
		end		-- for id in string.gmatch(filter.Who,pattern) do ends\
		-- Check if the boolean passes\
		if not loadstring(\"return \"..accStr)() then\
			return false\
		end\
	end		-- if filter.Access then ends\
\
	-- Check if Status Passes\
	if filter.Status then\
		-- Trim the string from leading and trailing spaces\
		local statStr = string.match(filter.Status,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(statStr,-1,-1)~=\",\" then\
			statStr = statStr .. \",\"\
		end\
		local matched = false\
		for stat in string.gmatch(statStr,\"(.-),\") do\
			-- Check if this status matches with what we have in the task\
			if task.Status == stat then\
				matched = true\
				break\
			end\
		end\
		if not matched then\
			return false\
		end\
	end\
\
	-- Check if Priority Passes\
	if filter.Priority then\
		-- Trim the string from leading and trailing spaces\
		local priStr = string.match(filter.Priority,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(priStr,-1,-1)~=\",\" then\
			priStr = priStr .. \",\"\
		end\
		local matched = false\
		for pri in string.gmatch(priStr,\"(.-),\") do\
			if pri == Karm.Globals.NoPriStr and not task.Priority then\
				matched = true\
				break\
			end\
			-- Check if this priority matches with what we have in the task\
			if task.Priority == pri then\
				matched = true\
				break\
			end\
		end\
		if not matched then\
			return false\
		end\
	end\
\
	-- Check if Date Due Passes\
	if filter.Due then\
		-- Trim the string from leading and trailing spaces\
		local dueStr = string.match(filter.Due,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(dueStr,-1,-1)~=\",\" then\
			dueStr = dueStr .. \",\"\
		end\
		local matched = false\
		for range in string.gmatch(dueStr,\"(.-),\") do\
			-- Check if this is Karm.Globals.NoDateStr\
			if range == Karm.Globals.NoDateStr and not task.Fin then\
				matched = true\
				break\
			end\
			-- See if this is a range or a single date\
			local strt,stp = string.match(range,\"(.-)%-(.*)\")\
			if not strt then\
				-- its not a range\
				strt = range\
				stp = range\
			end\
			strt = Karm.Utility.toXMLDate(strt)\
			stp = Karm.Utility.toXMLDate(stp)\
			if task.Due then\
				if strt <= task.Due and task.Due <=stp then\
					matched = true\
					break\
				end\
			end\
		end\
		if not matched then\
			return false\
		end\
	end\
\
	-- Check if Category Passes\
	if filter.Cat then\
		-- Trim the string from leading and trailing spaces\
		local catStr = string.match(filter.Cat,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(catStr,-1,-1)~=\",\" then\
			catStr = catStr .. \",\"\
		end\
		local matched = false\
		for cat in string.gmatch(catStr,\"(.-),\") do\
			-- Check if it matches Karm.Globals.NoCatStr\
			if cat == Karm.Globals.NoCatStr and not task.Cat then\
				matched = true\
				break\
			end\
			-- Check if this status matches with what we have in the task\
			if task.Cat == cat then\
				matched = true\
				break\
			end\
		end\
		if not matched then\
			return false\
		end\
	end\
\
	-- Check if Sub-Category Passes\
	if filter.SubCat then\
		-- Trim the string from leading and trailing spaces\
		local subCatStr = string.match(filter.SubCat,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(subCatStr,-1,-1)~=\",\" then\
			subCatStr = subCatStr .. \",\"\
		end\
		local matched = false\
		for subCat in string.gmatch(subCatStr,\"(.-),\") do\
			-- Check if it matches Karm.Globals.NoSubCatStr\
			if subCat == Karm.Globals.NoSubCatStr and not task.SubCat then\
				matched = true\
				break\
			end\
			-- Check if this status matches with what we have in the task\
			if task.SubCat == subCat then\
				matched = true\
				break\
			end\
		end\
		if not matched then\
			return false\
		end\
	end\
\
	-- Check if Tags pass\
	if filter.Tags then\
		local pattern = \"%'([%w%s%_]+)%'\"	-- Tags are allowed alphanumeric characters spaces and underscores\
		local tagStr = filter.Tags\
		for tag in string.gmatch(filter.Tags,pattern) do\
			-- Check if the tag exists in the task\
			local result = false\
			if tag == Karm.Globals.NoTagStr and not task.Tags then\
				result = true\
			elseif task.Tags then			\
				for i = 1,#task.Tags do\
					if task.Tags[i] == tag then\
						-- Found the tag in the task\
						result = true\
						break\
					end		-- if task.Tags[i] == tag then ends\
				end		-- for i = 1,#task.Tags ends\
			end\
			tagStr = string.gsub(tagStr,\"'\"..tag..\"'\",tostring(result))\
		end		-- for id in string.gmatch(filter.Tags,pattern) do ends\
		-- Check if the boolean passes\
		if not loadstring(\"return \"..tagStr)() then\
			return false\
		end\
	end		-- if filter.Access then ends\
	\
	-- Check if the Schedules pass\
	if filter.Schedules then\
		local schStr = filter.Schedules\
		for sch in string.gmatch(filter.Schedules,\"%'(.-)%'\") do\
			-- Check if this schedule chunk passes in the task\
			-- \"'Full,Estimate,12/1/2011-12/5/2011,12/10/2011-1/2/2012' and 'Overlap,Revision(L),12/1/2011-1/2/2012'\"\
			local typeMatch, typeSchedule, ranges, rangeStr, index, result\
			local firstComma = string.find(sch,\",\")\
			local secondComma = string.find(sch,\",\",firstComma + 1)\
			typeMatch = string.sub(sch,1,firstComma-1)\
			typeSchedule = string.sub(sch,firstComma + 1,secondComma - 1)\
			ranges = {[0]=string.sub(sch,secondComma + 1, -1),count=0}\
			rangeStr = ranges[0]\
			-- Make sure the string has \",\" at the end\
			if string.sub(rangeStr,-1,-1)~=\",\" then\
				rangeStr = rangeStr .. \",\"\
			end\
			-- Now separate individual date ranges\
			for range in string.gmatch(rangeStr,\"(.-),\") do\
				ranges.count = ranges.count + 1\
				ranges[ranges.count] = range\
			end\
			-- CHeck if the task has a Schedule item\
			if not task.Schedules then\
				if ranges[0] == Karm.Globals.NoDateStr then\
					result = true\
				end			\
				schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\
			else\
				-- Type of Schedule - Estimate, Committed, Revision(X) (L=Latest or the number of revision), Actual or Latest (means the latest schedule, note Actual is only latest if task is marked DONE)\
				index = nil\
				if string.upper(string.sub(typeSchedule,1,#\"ESTIMATE\")) == \"ESTIMATE\" then\
					if string.match(typeSchedule,\"%(%d-%)\") then\
						-- Get the index number\
						index = string.match(typeSchedule,\"%((%d-)%)\")\
					else  \
						-- Get the latest schedule index\
						if task.Schedules.Estimate then\
							index = #task.Schedules.Estimate\
						else\
							if ranges[0] == Karm.Globals.NoDateStr then\
								result = true\
							end\
							schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\
						end			\
					end\
					typeSchedule = \"Estimate\"\
				elseif string.upper(typeSchedule) == \"COMMITTED\" then\
					typeSchedule = \"Commit\"\
					index = 1\
				elseif string.upper(string.sub(typeSchedule,1,#\"REVISION\")) == \"REVISION\" then\
					if string.match(typeSchedule,\"%(%d-%)\") then\
						-- Get the index number\
						index = string.match(typeSchedule,\"%((%d-)%)\")\
					else  \
						-- Get the latest schedule index\
						if task.Schedules.Revs then\
							index = #task.Schedules.Revs\
						else\
							if ranges[0] == Karm.Globals.NoDateStr then\
								result = true\
							end\
							schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\
						end			\
					end\
					typeSchedule = \"Revs\"\
				elseif string.upper(typeSchedule) == \"ACTUAL\" then\
					typeSchedule = \"Actual\"\
					index = 1\
				elseif string.upper(typeSchedule) == \"LATEST\" then\
					-- Find the latest schedule in the task here\
					if string.upper(task.Status) == \"DONE\" and task.Schedules.Actual then\
						typeSchedule = \"Actual\"\
						index = 1\
					elseif task.Schedules.Revs then\
						-- Actual is not the latest one but Revision is \
						typeSchedule = \"Revs\"\
						index = task.Schedules.Revs.count\
					elseif task.Schedules.Commit then\
						-- Actual and Revisions don't exist but Commit does\
						typeSchedule = \"Commit\"\
						index = 1\
					elseif task.Schedules.Estimate then\
						-- The latest is Estimate\
						typeSchedule = \"Estimate\"\
						index = task.Schedules.Estimate.count\
					else\
						-- typeSchedule is latest but non of the schedule types exist\
						-- Check if the range is Karm.Globals.NoDateStr, if not this sch is false\
						local result = false\
						if ranges[0] == Karm.Globals.NoDateStr then\
							result = true\
						end\
						schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\
					end\
				else\
					wx.wxMessageBox(\"Invalid Type Schedule (\"..typeSchdule..\") specified in filter: \"..sch,\"Filter Error\",\
	                            wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)\
					return false\
				end		-- if string.upper(string.sub(typeSchedule,1,#\"ESTIMATE\") == \"ESTIMATE\" then ends  (SETTING of typeSchdule and index)\
			end		-- if not task.Schedules then\
			if index then\
				-- We have a typeSchedule and index\
				-- Now loop through the schedule of typeSchedule and index\
				local result\
				if string.upper(typeMatch) == \"OVERLAP\" then\
					result = false\
				else\
					result = true\
				end\
				-- First check if range is Karm.Globals.NoDateStr then this schedule should not exist for filter to pass\
				if ranges[0] == Karm.Globals.NoDateStr then\
					if task.Schedules[typeSchedule] and not task.Schedules[typeSchedule][index] then\
						result = true\
					else\
						result = false\
					end\
				else\
					if task.Schedules[typeSchedule] and task.Schedules[typeSchedule][index] then\
						for i = 1,#task.Schedules[typeSchedule][index].Period do\
							-- Is the date in range?\
							local inrange = false\
							for j = 1,#ranges do\
								local strt,stp = string.match(ranges[j],\"(.-)%-(.*)\")\
								if not strt then\
									-- its not a range\
									strt = ranges[j]\
									stp = ranges[j]\
								end\
								strt = Karm.Utility.toXMLDate(strt)\
								stp = Karm.Utility.toXMLDate(stp)\
								if strt <= task.Schedules[typeSchedule][index].Period[i].Date and task.Schedules[typeSchedule][index].Period[i].Date <=stp then\
									inrange = true\
								end\
							end		-- for j = 1,#ranges do ends\
							if inrange and string.upper(typeMatch) == \"OVERLAP\" then\
								-- This date overlaps\
								result = true\
								break\
							elseif not inrange and string.upper(typeMatch) == \"FULL\" then\
								-- This portion is not contained in filter\
								result = false\
								break\
							end\
						end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends\
					else\
						-- Task Schedule for the particular index does not exist and noDateStr was not specified so this is not a match\
						result = false\
					end		-- if task.Schedules[typeSchedule] and task.Schedules[typeSchedule][index] then ends\
				end	-- if ranges[0] == Karm.Globals.NoDateStr then ends\
				schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\
			end		-- if index then ends\
		end		-- for sch in string.gmatch(filter.Schedules,\"%'(.-)%'\") do ends\
		-- Check if the boolean passes\
		if not loadstring(\"return \"..schStr)() then\
			return false\
		end\
	end		-- if filter.Schedules then ends\
\
	if filter.Script then\
		local safeenv = {}\
		setmetatable(safeenv,{__index = Karm.Globals.safeenv})\
		local func,message = loadstring(filter.Script)\
		if not func then\
			return false\
		end\
		safeenv.task = task\
		setfenv(func,safeenv)\
		local stat,err\
		stat,err = pcall(func)\
		if not stat then\
			wx.wxMessageBox(\"Error Running Script:\\n\"..err,\"Error\",wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)\
		end			\
		if not safeenv.result then\
			return false\
		end\
	end\
	-- All pass\
	return true\
end		-- function Karm.FilterObject.validateTask(filter, task) ends\
"
__MANY2ONEFILES['FilterForm']="local requireLuaString = requireLuaString\
-----------------------------------------------------------------------------\
-- Application: Karm\
-- Purpose:     Karm application Criteria Entry form UI creation and handling file\
-- Author:      Milind Gupta\
-- Created:     2/09/2012\
-----------------------------------------------------------------------------\
local prin\
if Karm.Globals.__DEBUG then\
	prin = print\
end\
local print = prin \
local wx = wx\
local io = io\
local wxaui = wxaui\
local bit = bit\
local GUI = Karm.GUI\
local tostring = tostring\
local loadfile = loadfile\
local loadstring = loadstring\
local setfenv = setfenv\
local string = string\
local Globals = Karm.Globals\
local setmetatable = setmetatable\
local NewID = Karm.NewID\
local type = type\
local math = math\
local error = error\
local modname = ...\
local tableToString = Karm.Utility.tableToString\
local pairs = pairs\
local applyFilterHier = Karm.FilterObject.applyFilterHier\
local collectFilterDataHier = Karm.accumulateTaskDataHier\
local CW = requireLuaString('CustomWidgets')\
\
\
local GlobalFilter = function() \
		return Karm.Filter \
	end\
	\
local SData = function()\
		return Karm.SporeData\
	end\
\
local MainFilter\
local SporeData\
\
----------------------------------------------------------\
--module(modname)\
-- NOT USING THE module KEYWORD SINCE IT DOES THIS ALSO _G[modname] = M\
local M = {}\
package.loaded[modname] = M\
setfenv(1,M)\
----------------------------------------------------------\
\
-- Local filter table to store the filter criteria\
local filter = {}\
local filterData = {}\
\
local noStr = {\
	Cat = Globals.NoCatStr,\
	SubCat = Globals.NoSubCatStr,\
	Priority = Globals.NoPriStr,\
	Due = Globals.NoDateStr,\
	Fin = Globals.NoDateStr,\
	ScheduleRange = Globals.NoDateStr,\
	Tags = Globals.NoTagStr,\
	Access = Globals.NoAccessIDStr\
}\
\
local function SelTaskPress(event)\
	setfenv(1,package.loaded[modname])\
	local frame = wx.wxFrame(frame, wx.wxID_ANY, \"Select Task\", wx.wxDefaultPosition,\
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)\
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
	local taskTree = wx.wxTreeCtrl(frame, wx.wxID_ANY, wx.wxDefaultPosition,wx.wxSize(0.9*GUI.initFrameW, 0.9*GUI.initFrameH),bit.bor(wx.wxTR_SINGLE,wx.wxTR_HAS_BUTTONS))\
	MainSizer:Add(taskTree, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
	local OKButton = wx.wxButton(frame, wx.wxID_ANY, \"OK\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
	local CancelButton = wx.wxButton(frame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
	local CheckBox = wx.wxCheckBox(frame, wx.wxID_ANY, \"Subtasks\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
	\
	if filter.TasksSet and filter.TasksSet[1].Children then\
		CheckBox:SetValue(true)\
	end\
	buttonSizer:Add(OKButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	buttonSizer:Add(CancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	buttonSizer:Add(CheckBox,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	\
	-- Now populate the tree with all the tasks\
	\
	-- Add the root\
	local root = taskTree:AddRoot(\"Task Spores\")\
	local treeData = {}\
	treeData[root:GetValue()] = {Key = Globals.ROOTKEY, Parent = nil, Title = \"Task Spores\"}\
    if SporeData[0] > 0 then\
-- Populate the tree control view\
		local count = 0\
		-- Loop through all the spores\
        for k,v in pairs(SporeData) do\
        	if k~=0 then\
            -- Get the tasks in the spore\
-- Add the spore to the TaskTree\
				-- Find the name of the file\
				local strVar\
        		local intVar1 = -1\
				count = count + 1\
            	for intVar = #k,1,-1 do\
                	if string.sub(k, intVar, intVar) == \".\" then\
                    	intVar1 = intVar\
                	end\
                	if string.sub(k, intVar, intVar) == \"\\\\\" or string.sub(k, intVar, intVar) == \"/\" then\
                    	strVar = string.sub(k, intVar + 1, intVar1-1)\
                    	break\
                	end\
            	end\
            	-- Add the spore node\
	            local currNode = taskTree:AppendItem(root,strVar)\
				treeData[currNode:GetValue()] = {Key = Globals.ROOTKEY..k, Parent = root, Title = strVar}\
				if filter.TasksSet and #filter.TasksSet[1].TaskID > #Globals.ROOTKEY and \
				  string.sub(filter.TasksSet[1].TaskID,#Globals.ROOTKEY + 1, -1) == k then\
					taskTree:EnsureVisible(currNode)\
					taskTree:SelectItem(currNode)\
				end\
				local taskList = applyFilterHier(filter, v)\
-- Now add the tasks under the spore in the TaskTree\
            	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore\
	                -- Add the 1st element under the spore\
	                local parent = currNode\
		            currNode = taskTree:AppendItem(parent,taskList[1].Title)\
					treeData[currNode:GetValue()] = {Key = taskList[1].TaskID, Parent = parent, Title = taskList[1].Title}\
	                for intVar = 2,taskList.count do\
	                	local cond1 = treeData[currNode:GetValue()].Key ~= Globals.ROOTKEY..k\
	                	local cond2 = #taskList[intVar].TaskID > #treeData[currNode:GetValue()].Key\
	                	local cond3 = string.sub(taskList[intVar].TaskID, 1, #treeData[currNode:GetValue()].Key + 1) == treeData[currNode:GetValue()].Key..\"_\"\
                    	while cond1 and not (cond2 and cond3) do\
                        	-- Go up the hierarchy\
                        	currNode = treeData[currNode:GetValue()].Parent\
		                	cond1 = treeData[currNode:GetValue()].Key ~= Globals.ROOTKEY..k\
		                	cond2 = #taskList[intVar].TaskID > #treeData[currNode:GetValue()].Key\
		                	cond3 = string.sub(taskList[intVar].TaskID, 1, #treeData[currNode:GetValue()].Key + 1) == treeData[currNode:GetValue()].Key..\"_\"\
                        end\
                    	-- Now currNode has the node which is the right parent\
		                parent = currNode\
			            currNode = taskTree:AppendItem(parent,taskList[intVar].Title)\
						treeData[currNode:GetValue()] = {Key = taskList[intVar].TaskID, Parent = parent, Title = taskList[intVar].Title}\
                    end\
	            end  -- if taskList.count > 0 then ends\
			end		-- if k~=0 then ends\
-- Repeat for all spores\
        end		-- for k,v in pairs(SporeData) do ends\
    end  -- if SporeData[0] > 0 then ends\
    \
	-- Expand the root element\
	taskTree:Expand(root)\
	\
	-- Connect the button events\
	OKButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
	function (event)\
		setfenv(1,package.loaded[modname])\
		local sel = taskTree:GetSelection()\
		-- Setup the filter\
		filter.TasksSet = {}\
		if treeData[sel:GetValue()].Key == Globals.ROOTKEY then\
			filter.TasksSet = nil\
		else\
			filter.TasksSet[1] = {}\
			-- This is a spore node\
			if CheckBox:GetValue() then\
				filter.TasksSet[1].Children = true\
			end\
			filter.TasksSet[1].TaskID = treeData[sel:GetValue()].Key\
			filter.TasksSet[1].Title =  treeData[sel:GetValue()].Title\
		end\
		-- Setup the label properly\
		if filter.TasksSet then\
			if filter.TasksSet[1].Children then\
				FilterTask:SetLabel(taskTree:GetItemText(sel)..\" and Children\")\
			else\
				FilterTask:SetLabel(taskTree:GetItemText(sel))\
			end\
		else\
			FilterTask:SetLabel(\"No Task Selected\")\
		end	\
		frame:Close()\
	end\
	)\
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
	function (event)\
		setfenv(1,package.loaded[modname])		\
		frame:Close()\
	end\
	)\
	\
	\
	frame:SetSizer(MainSizer)\
	MainSizer:SetSizeHints(frame)\
	frame:Layout()\
	frame:Show(true)\
end		-- local function SelTaskPress(event) ends\
\
local function initializeFilterForm(filterData)\
	-- Clear Task Selection\
	FilterTask:SetLabel(\"No Task Selected\")\
	-- Clear Category\
	CatCtrl:ResetCtrl()\
	-- Clear Sub-Category\
	SubCatCtrl:ResetCtrl()\
	-- Clear Priority\
	PriCtrl:ResetCtrl()\
	-- Clear Status\
	StatCtrl:ResetCtrl()\
	-- Clear Tags List\
	TagList:DeleteAllItems()\
	TagBoolCtrl:ResetCtrl()\
	-- Clear Dates\
	dateStarted:ResetCtrl()\
	dateFinished:ResetCtrl()\
	dateDue:ResetCtrl()\
	-- Who and Access\
	whoCtrl:ResetCtrl()\
	WhoBoolCtrl:ResetCtrl()\
	accCtrl:ResetCtrl()\
	accBoolCtrl:ResetCtrl()\
	-- Schedules\
	schDateRanges:ResetCtrl()\
	SchBoolCtrl:ResetCtrl()\
	filter = {}		-- Clear the filter\
	-- Fill the data in the controls\
	CatCtrl:AddListData(filterData.Cat)\
	SubCatCtrl:AddListData(filterData.SubCat)\
	PriCtrl:AddListData(filterData.Priority)\
	StatCtrl:AddListData(Globals.StatusList)\
	ScriptBox:Clear()\
	if filterData.Tags then\
		for i=1,#filterData.Tags do\
			CW.InsertItem(TagList,filterData.Tags[i])\
		end\
	end\
	if filterData.Who then\
		for i=1,#filterData.Who do\
			whoCtrl:InsertItem(filterData.Who[i], false)\
		end\
	end\
	\
	if filterData.Access then\
		for i=1,#filterData.Access do\
			accCtrl:InsertItem(filterData.Access[i], false)\
		end\
	end\
end\
\
local function setfilter(f)\
	-- Initialize the form\
	initializeFilterForm(filterData)\
	-- Set the task details\
	local str = \"\"\
	if f.Tasks then\
		filter.TasksSet = {[1]={}}\
		if f.Tasks[1].Title then\
			str = f.Tasks[1].Title\
			filter.TasksSet[1].Title = str\
		else\
			for k,v in pairs(SporeData) do\
				if k~=0 then\
					local taskList = applyFilterHier({Tasks={[1]={TaskID = f.Tasks.TaskID}}},v)\
					if #taskList then\
						str = taskList[1].Title\
						break\
					end\
				end		-- if k~=0 then ends\
			end		-- for k,v in pairs(SporeData) do ends\
			if not str then\
				str = \"TASK ID: \"..f.Tasks[1].TaskID\
				filter.TasksSet[1].Title = str\
			end\
		end	\
		filter.TasksSet[1].TaskID = f.Tasks[1].TaskID\
		filter.TasksSet[1].Children = f.Tasks[1].Children\
		if f.Tasks[1].Children then\
			str = str..\" and Children\"\
		end\
		FilterTask:SetLabel(str)\
	end\
	-- Set Category data\
	if f.Cat then\
		-- Separate out the items in the comma\
		-- Trim the string from leading and trailing spaces\
		local catStr = string.match(f.Cat,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(catStr,-1,-1)~=\",\" then\
			catStr = catStr .. \",\"\
		end\
		local items = {}\
		for cat in string.gmatch(catStr,\"(.-),\") do\
			-- Trim leading and trailing spaces\
			cat = string.match(cat,\"^%s*(.-)%s*$\")			\
			-- Check if it matches Globals.NoCatStr\
			if cat == Globals.NoCatStr then\
				CatCtrl.CheckBox:SetValue(true)\
			else\
				items[#items + 1] = cat\
			end\
		end\
		CatCtrl:AddSelListData(items)\
	end		-- if f.Cat then ends\
	-- Set Sub-Category data\
	if f.SubCat then\
		-- Separate out the items in the comma\
		-- Trim the string from leading and trailing spaces\
		local subCatStr = string.match(f.SubCat,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(subCatStr,-1,-1)~=\",\" then\
			subCatStr = subCatStr .. \",\"\
		end\
		local items = {}\
		for subCat in string.gmatch(subCatStr,\"(.-),\") do\
			-- Trim leading and trailing spaces\
			subCat = string.match(subCat,\"^%s*(.-)%s*$\")			\
			-- Check if it matches Globals.NoSubCatStr\
			if subCat == Globals.NoSubCatStr then\
				SubCatCtrl.CheckBox:SetValue(true)\
			else\
				items[#items + 1] = subCat\
			end\
		end\
		SubCatCtrl:AddSelListData(items)\
	end		-- if f.Cat then ends\
	if f.Tags then\
		TagBoolCtrl:setExpression(f.Tags)\
	end		-- if f.Tags then ends\
	-- Set Priority data\
	if f.Priority then\
		-- Separate out the items in the comma\
		-- Trim the string from leading and trailing spaces\
		local priStr = string.match(f.Priority,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(priStr,-1,-1)~=\",\" then\
			priStr = priStr .. \",\"\
		end\
		local items = {}\
		for pri in string.gmatch(priStr,\"(.-),\") do\
			-- Trim leading and trailing spaces\
			pri = string.match(pri,\"^%s*(.-)%s*$\")			\
			-- Check if it matches Globals.NoPriStr\
			if pri == Globals.NoPriStr then\
				PriCtrl.CheckBox:SetValue(true)\
			else\
				items[#items + 1] = pri\
			end\
		end\
		PriCtrl:AddSelListData(items)\
	end		-- if f.Priority then ends\
	-- Set Status data\
	if f.Status then\
		-- Separate out the items in the comma\
		-- Trim the string from leading and trailing spaces\
		local statStr = string.match(f.Status,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(statStr,-1,-1)~=\",\" then\
			statStr = statStr .. \",\"\
		end\
		local items = {}\
		for stat in string.gmatch(statStr,\"(.-),\") do\
			-- Trim leading and trailing spaces\
			stat = string.match(stat,\"^%s*(.-)%s*$\")			\
			items[#items + 1] = stat\
		end\
		StatCtrl:AddSelListData(items)\
	end		-- if f.Status then ends\
	-- Who items\
	if f.Who then\
		WhoBoolCtrl:setExpression(f.Who)\
	end\
	-- Access items\
	if f.Access then\
		accBoolCtrl:setExpression(f.Access)\
	end		-- if f.Tags then ends\
	-- Set Start Date data\
	if f.Start then\
		do\
			-- Separate out the items in the comma\
			-- Trim the string from leading and trailing spaces\
			local strtStr = string.match(f.Start,\"^%s*(.-)%s*$\")\
			-- Make sure the string has \",\" at the end\
			if string.sub(strtStr,-1,-1)~=\",\" then\
				strtStr = strtStr .. \",\"\
			end\
			local items = {}\
			for strt in string.gmatch(strtStr,\"(.-),\") do\
				-- Trim leading and trailing spaces\
				strt = string.match(strt,\"^%s*(.-)%s*$\")\
				if strt ~= \"\" then			\
					items[#items + 1] = strt\
				end\
			end\
			dateStarted:setRanges(items)\
		end		-- do for f.Start\
	end	\
	-- Set Due Date data\
	if f.Due then\
		-- Separate out the items in the comma\
		-- Trim the string from leading and trailing spaces\
		local dueStr = string.match(f.Due,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(dueStr,-1,-1)~=\",\" then\
			dueStr = dueStr .. \",\"\
		end\
		local items = {}\
		dateDue:setCheckBoxState(nil)\
		for due in string.gmatch(dueStr,\"(.-),\") do\
			-- Trim leading and trailing spaces\
			due = string.match(due,\"^%s*(.-)%s*$\")\
			if due == noStr.Due then\
				dateDue:setCheckBoxState(true)\
			elseif due ~= \"\" then			\
				items[#items + 1] = due\
			end\
		end\
		dateDue:setRanges(items)\
	end		-- if f.Due ends here	\
	-- Set Finish Date data\
	if f.Fin then\
		-- Separate out the items in the comma\
		-- Trim the string from leading and trailing spaces\
		local finStr = string.match(f.Fin,\"^%s*(.-)%s*$\")\
		-- Make sure the string has \",\" at the end\
		if string.sub(finStr,-1,-1)~=\",\" then\
			finStr = finStr .. \",\"\
		end\
		local items = {}\
		dateFinished:setCheckBoxState(nil)\
		for fin in string.gmatch(finStr,\"(.-),\") do\
			-- Trim leading and trailing spaces\
			fin = string.match(fin,\"^%s*(.-)%s*$\")\
			if fin == noStr.Fin then\
				dateFinished:setCheckBoxState(true)\
			elseif fin ~= \"\" then			\
				items[#items + 1] = fin\
			end\
		end\
		dateFinished:setRanges(items)\
	end		-- if f.Due ends here	\
	-- Set the Schedules Data\
	if f.Schedules then\
		SchBoolCtrl:setExpression(f.Schedules)\
	end		-- if f.Schedules ends here\
	-- Custom Script\
	if f.Script then\
		ScriptBox:SetValue(f.Script)\
	end\
end\
\
local function synthesizeFilter()\
	local f = {}\
	-- Get the tasks information\
	if filter.TasksSet then\
		f.Tasks = filter.TasksSet\
	end\
	-- Get Who information here\
	f.Who = WhoBoolCtrl:BooleanExpression()\
	-- Date Started\
	local str = \"\"\
	local items = dateStarted:getSelectedItems()\
	for i = 1,#items do\
		str = str..items[i]..\",\"\
	end\
	if str ~= \"\" then \
		f.Start = str:sub(1,-2)\
	end\
	-- Date Finished\
	str = \"\"\
	items = dateFinished:getSelectedItems()\
	for i = 1,#items do\
		str = str..items[i]..\",\"\
	end \
	if items[0] then\
		str = str..Globals.NoDateStr..\",\"\
	end\
	if str ~= \"\" then\
		f.Fin = str:sub(1,-2)\
	end\
	-- Access information\
	f.Access = accBoolCtrl:BooleanExpression()\
	-- Status Information\
	str = \"\"\
	items = StatCtrl:getSelectedItems()\
	for i = 1,#items do\
		str = str..items[i]..\",\"\
	end\
	if str ~= \"\" then \
		f.Status = str:sub(1,-2)\
	end\
	-- Priority\
	str = \"\"\
	items = PriCtrl:getSelectedItems()\
	for i = 1,#items do\
		str = str..items[i]..\",\"\
	end \
	if items[0] then\
		str = str..Globals.NoPriStr..\",\"\
	end\
	if str ~= \"\" then\
		f.Priority = str:sub(1,-2)\
	end\
	-- Due Date\
	str = \"\"\
	items = dateDue:getSelectedItems()\
	for i = 1,#items do\
		str = str..items[i]..\",\"\
	end \
	if items[0] then\
		str = str..Globals.NoDateStr..\",\"\
	end\
	if str ~= \"\" then\
		f.Due = str:sub(1,-2)\
	end\
	-- Category\
	str = \"\"\
	items = CatCtrl:getSelectedItems()\
	for i = 1,#items do\
		str = str..items[i]..\",\"\
	end \
	if items[0] then\
		str = str..Globals.NoCatStr..\",\"\
	end\
	if str ~= \"\" then\
		f.Cat = str:sub(1,-2)\
	end\
	-- Sub-Category\
	str = \"\"\
	items = SubCatCtrl:getSelectedItems()\
	for i = 1,#items do\
		str = str..items[i]..\",\"\
	end \
	if items[0] then\
		str = str..Globals.NoSubCatStr..\",\"\
	end\
	if str ~= \"\" then\
		f.SubCat = str:sub(1,-2)\
	end\
	-- Tags\
	f.Tags = TagBoolCtrl:BooleanExpression()\
	if TagCheckBox:GetValue() then\
		f.Tags = \"(\"..f.Tags..\") or \"..Globals.NoTagStr\
	end\
	-- Schedule\
	f.Schedules = SchBoolCtrl:BooleanExpression()\
	-- Custom Script\
	if ScriptBox:GetValue() ~= \"\" then\
		local script = ScriptBox:GetValue()\
		local result, msg = loadstring(script)\
		if not result then\
			wx.wxMessageBox(\"Unable to compile the script. Error: \"..msg..\".\\n Please correct and try again.\",\
                            \"Script Compile Error\",wx.wxOK + wx.wxCENTRE, frame)\
            return nil\
		end\
		f.Script = script\
	end\
	return f\
end\
\
local function loadFilter(event)\
	setfenv(1,package.loaded[modname])\
	local ValidFilter = function(file)\
		local safeenv = {}\
		setmetatable(safeenv, {__index = Globals.safeenv})\
		local f,message = loadfile(file)\
		if not f then\
			return nil,message\
		end\
		setfenv(f,safeenv)\
		f()\
		if safeenv.filter and type(safeenv.filter) == \"table\" then\
			if safeenv.filter.Script then\
				f, message = loadstring(safeenv.filter.Script)\
				if not f then\
					return nil,\"Cannot compile custom script in filter. Error: \"..message\
				end\
			end\
			return safeenv.filter\
		else\
			return nil,\"Cannot find a valid filter in the file.\"\
		end\
	end\
    local fileDialog = wx.wxFileDialog(frame, \"Open file\",\
                                       \"\",\
                                       \"\",\
                                       \"Karm Filter files (*.kff)|*.kff|Text files (*.txt)|*.txt|All files (*)|*\",\
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)\
    if fileDialog:ShowModal() == wx.wxID_OK then\
    	local result,message = ValidFilter(fileDialog:GetPath())\
        if not result then\
            wx.wxMessageBox(\"Unable to load file '\"..fileDialog:GetPath()..\"'.\\n \"..message,\
                            \"File Load Error\",\
                            wx.wxOK + wx.wxCENTRE, frame)\
        else\
        	setfilter(result)\
        end\
    end\
    fileDialog:Destroy()\
end\
\
local function saveFilter(event)\
	setfenv(1,package.loaded[modname])\
    local fileDialog = wx.wxFileDialog(frame, \"Save File\",\
                                       \"\",\
                                       \"\",\
                                       \"Karm Filter files (*.kff)|*.kff|Text files (*.txt)|*.txt|All files (*)|*\",\
                                       wx.wxFD_SAVE)\
    if fileDialog:ShowModal() == wx.wxID_OK then\
    	local file,err = io.open(fileDialog:GetPath(),\"w+\")\
    	if not file then\
            wx.wxMessageBox(\"Unable to save as file '\"..fileDialog:GetPath()..\"'.\\n \"..err,\
                            \"File Save Error\",\
                            wx.wxOK + wx.wxCENTRE, frame)\
        else\
        	local fil = synthesizeFilter()\
        	if fil then\
        		file:write(\"filter=\"..tableToString(fil))\
        	end\
        	file:close()\
        end\
    end\
    fileDialog:Destroy()\
\
end\
\
-- Customized multiselect control\
do\
\
	local UpdateFilter = function(o)\
		local SelList = o:getSelectedItems()\
		local filterIndex = o.filterIndex\
		local str = \"\"\
		for i = 1,#SelList do\
			str = str..SelList[i]..\",\"\
		end\
		-- Finally Check if none also selected\
		if SelList[0] then\
			str = str..noStr[filterIndex]..\",\"\
		end\
		if str ~= \"\" then\
			filter[filterIndex]=string.sub(str,1,-2) -- remove the comma and add it\
		else\
			filter[filterIndex]=nil\
		end\
	end\
\
	MultiSelectCtrl = function(parent, filterIndex, noneSelection, LItems, RItems)\
		if not filterIndex then\
			error(\"Need a filterIndex for the MultiSelect Control\",2)\
		end\
		local o = CW.MultiSelectCtrl(parent,LItems,RItems,noneSelection)\
		o.filterIndex = filterIndex\
		o.UpdateFilter = UpdateFilter\
		return o\
	end\
\
end\
\
-- Customized Date Range control\
do\
\
	local UpdateFilter = function(o)\
		local SelList = o:getSelectedItems()\
		local filterIndex = o.filterIndex\
		local str = \"\"\
		for i = 1,#SelList do\
			str = str..SelList[i]..\",\"\
		end\
		-- Finally Check if none also selected\
		if SelList[0] then\
			str = str..noStr[filterIndex]..\",\"\
		end\
		if str ~= \"\" then\
			filter[filterIndex]=string.sub(str,1,-2) -- remove the comma and add it\
		else\
			filter[filterIndex]=nil\
		end\
	end\
\
	DateRangeCtrl = function(parent, filterIndex, noneSelection, heading)\
		if not filterIndex then\
			error(\"Need a filterIndex for the Date Range Control\",2)\
		end\
		local o = CW.DateRangeCtrl(parent, noneSelection, heading)\
		o.filterIndex = filterIndex\
		o.UpdateFilter = UpdateFilter\
		return o\
	end\
\
end\
\
-- Customized Boolean Tree Control\
do\
\
	local UpdateFilter = function(o)\
		local filterText = o:BooleanExpression()\
		if filterText == \"\" then\
			filter[o.filterIndex]=nil\
		else\
			filter[o.filterIndex]=filterText\
		end\
	end\
	\
	BooleanTreeCtrl = function(parent,sizer,getInfoFunc,filterIndex)\
		if not filterIndex then\
			error(\"Need a filterIndex for the Boolean Tree Control\",2)\
		end\
		local o = CW.BooleanTreeCtrl(parent,sizer,getInfoFunc)\
		o.filterIndex = filterIndex\
		o.UpdateFilter = UpdateFilter\
		return o	\
	end\
\
end\
\
-- Customized Check List Control\
do\
	local getSelectionFunc = function(obj)\
		-- Return the selected item in List\
		local o = obj		-- Declare an upvalue\
		return function()\
			local items = o:getSelectedItems()\
			if not items[1] then\
				return nil\
			else\
				return items[1].itemText..\",\"..items[1].checked\
			end\
		end\
	end\
	\
	CheckListCtrl = function(parent,noneSelection,checkedText,uncheckedText)\
		local o = CW.CheckListCtrl(parent,noneSelection,checkedText,uncheckedText,true)\
		o.getSelectionFunc = getSelectionFunc\
		return o\
	end\
\
end\
\
function filterFormActivate(parent, callBack)\
	MainFilter = GlobalFilter()\
	SporeData = SData()\
	-- Accumulate Filter Data across all spores\
	-- Loop through all the spores\
	for k,v in pairs(SporeData) do\
		if k~=0 then\
			collectFilterDataHier(filterData,v)\
		end		-- if k~=0 then ends\
	end		-- for k,v in pairs(SporeData) do ends\
	\
	frame = wx.wxFrame(parent, wx.wxID_ANY, \"Filter Form\", wx.wxDefaultPosition,\
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)\
	-- Create tool bar\
	ID_LOAD = NewID()\
	ID_SAVE = NewID()\
	local toolBar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)\
	local toolBmpSize = toolBar:GetToolBitmapSize()\
\
	toolBar:AddTool(ID_LOAD, \"Load\", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DIR_UP, wx.wxART_MENU, toolBmpSize), \"Load Filter Criteria\")\
	toolBar:AddTool(ID_SAVE, \"Save\", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize), \"Save Filter Criteria\")\
	toolBar:Realize()\
	\
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
		MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)\
\
		-- Task, Categories and Sub-Categories Page\
		TandC = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			local TandCSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
				local TaskSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
				SelTaskButton = wx.wxButton(TandC, wx.wxID_ANY, \"Select Task\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				TaskSizer:Add(SelTaskButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				FilterTask = wx.wxStaticText(TandC, wx.wxID_ANY, \"No Task Selected\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
				TaskSizer:Add(FilterTask, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				ClearTaskButton = wx.wxButton(TandC, wx.wxID_ANY, \"Clear Task\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
				TaskSizer:Add(ClearTaskButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				TandCSizer:Add(TaskSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
				CategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, \"Select Categories\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
				TandCSizer:Add(CategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				\
				-- Category List boxes and buttons\
				CatCtrl = MultiSelectCtrl(TandC,\"Cat\",true,filterData.Cat)\
				TandCSizer:Add(CatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				\
				SubCategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, \"Select Sub-Categories\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
				TandCSizer:Add(SubCategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				-- Sub Category Listboxes and Buttons\
				SubCatCtrl = MultiSelectCtrl(TandC,\"SubCat\",true,filterData.SubCat)\
				TandCSizer:Add(SubCatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			\
			TandC:SetSizer(TandCSizer)\
			TandCSizer:SetSizeHints(TandC)\
		MainBook:AddPage(TandC, \"Task and Category\")\
		\
		-- Priorities Status and Tags page\
		PSandTag = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			local PSandTagSizer = wx.wxBoxSizer(wx.wxVERTICAL) \
				PriorityLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, \"Select Priorities\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
				PSandTagSizer:Add(PriorityLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				\
				-- Priority List boxes and buttons\
				PriCtrl = MultiSelectCtrl(PSandTag,\"Priority\",true,filterData.Priority)\
				PSandTagSizer:Add(PriCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
				StatusLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, \"Select Status\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
				PSandTagSizer:Add(StatusLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				\
				-- Status List boxes and buttons\
				StatCtrl = MultiSelectCtrl(PSandTag,\"Status\",false,Globals.StatusList)\
				PSandTagSizer:Add(StatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
				TagsLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, \"Select Tags\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
				PSandTagSizer:Add(TagsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
				\
				-- Tag List box, buttons and tree\
				local TagSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
					local TagListSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
						TagList = wx.wxListCtrl(PSandTag, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(0.1*GUI.initFrameW, 0.1*GUI.initFrameH),\
							bit.bor(wx.wxLC_REPORT,wx.wxLC_NO_HEADER,wx.wxLC_SINGLE_SEL))\
						-- Populate the tag list here\
						--local col = wx.wxListItem()\
						--col:SetId(0)\
						TagList:InsertColumn(0,\"Tags\")\
						if filterData.Tags then\
							for i=1,#filterData.Tags do\
								CW.InsertItem(TagList,filterData.Tags[i])\
							end\
						end\
						TagListSizer:Add(TagList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
						TagCheckBox = wx.wxCheckBox(PSandTag, wx.wxID_ANY, \"None Also passes\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
						TagListSizer:Add(TagCheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
						\
					TagSizer:Add(TagListSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
					TagBoolCtrl = BooleanTreeCtrl(PSandTag,TagSizer,\
						function()\
							-- Return the selected item in Tag List\
							local item = TagList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\
							if item == -1 then\
								return nil\
							else \
								return TagList:GetItemText(item)		\
							end\
						end, \
					\"Tags\")\
				PSandTagSizer:Add(TagSizer, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
			PSandTag:SetSizer(PSandTagSizer)\
			PSandTagSizer:SetSizeHints(PSandTag)\
		MainBook:AddPage(PSandTag, \"Priorities,Status and Tags\")\
		\
		-- Date Started, Date Finished and Due Date Page\
		DatesPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			local DatesPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) \
			\
			-- Date Started Control\
			dateStarted = DateRangeCtrl(DatesPanel,\"Start\",false,\"Date Started\")\
			DatesPanelSizer:Add(dateStarted.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			-- Date Finished Control\
			dateFinished = DateRangeCtrl(DatesPanel,\"Fin\",true,\"Date Finished\")\
			DatesPanelSizer:Add(dateFinished.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			-- Due Date Control\
			dateDue = DateRangeCtrl(DatesPanel,\"Due\",true,\"Due Date\")\
			DatesPanelSizer:Add(dateDue.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			\
\
			DatesPanel:SetSizer(DatesPanelSizer)\
			DatesPanelSizer:SetSizeHints(DatesPanel)\
		MainBook:AddPage(DatesPanel, \"Dates:Due,Started,Finished\")\
\
		-- Who and Access IDs page\
		AccessPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			local AccessPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)\
			\
			local whoSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
			local accSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) \
			\
			local whoLabel = wx.wxStaticText(AccessPanel, wx.wxID_ANY, \"Select Responsible People (Check means Inactive)\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
			AccessPanelSizer:Add(whoLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			\
			whoCtrl = CheckListCtrl(AccessPanel,false,\"I\",\"A\")\
			-- Populate the IDs\
			if filterData.Who then\
				for i = 1,#filterData.Who do\
					whoCtrl:InsertItem(filterData.Who[i], false)\
				end\
			end\
			whoSizer:Add(whoCtrl.Sizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
			WhoBoolCtrl = BooleanTreeCtrl(AccessPanel,whoSizer,whoCtrl:getSelectionFunc(), \"Who\")\
			AccessPanelSizer:Add(whoSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
			\
			local accLabel = wx.wxStaticText(AccessPanel, wx.wxID_ANY, \"Select People for access (Check means Read/Write Access)\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
			AccessPanelSizer:Add(accLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
			accCtrl = CheckListCtrl(AccessPanel,false,\"W\",\"R\")\
			-- Populate the IDs\
			if filterData.Access then\
				for i = 1,#filterData.Access do\
					accCtrl.InsertItem(accCtrl,filterData.Access[i], false)\
				end\
			end\
			accSizer:Add(accCtrl.Sizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
			accBoolCtrl = BooleanTreeCtrl(AccessPanel,accSizer,accCtrl:getSelectionFunc(), \"Access\")\
			AccessPanelSizer:Add(accSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
\
			AccessPanel:SetSizer(AccessPanelSizer)\
			AccessPanelSizer:SetSizeHints(AccessPanel)\
		MainBook:AddPage(AccessPanel, \"Access\")\
		\
		-- Schedules Page\
		SchPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			local SchPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) \
			local duSizer = wx.wxBoxSizer(wx.wxVERTICAL)	-- Sizer for Date unit elements\
			\
			local typeMatchLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, \"Select Type of Matching\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
			duSizer:Add(typeMatchLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
			TypeMatch = wx.wxChoice(SchPanel, wx.wxID_ANY,wx.wxDefaultPosition, wx.wxDefaultSize,{\"Full\",\"Overlap\"})\
			duSizer:Add(TypeMatch,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
			TypeMatch:SetSelection(1)\
			\
			local typeSchLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, \"Select Type of Schedule\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
			duSizer:Add(typeSchLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
			TypeSch = wx.wxChoice(SchPanel, wx.wxID_ANY,wx.wxDefaultPosition, wx.wxDefaultSize,{\"Estimate\",\"Committed\",\"Revisions\",\"Actual\", \"Latest\"})\
			duSizer:Add(TypeSch,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
			TypeSch:SetSelection(2)\
						\
			local SchRevLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, \"Select Revision\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
			duSizer:Add(SchRevLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
\
			SchRev = wx.wxComboBox(SchPanel, wx.wxID_ANY,\"Latest\",wx.wxDefaultPosition, wx.wxDefaultSize,{\"Latest\"})\
			duSizer:Add(SchRev,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
\
			-- Event connect to enable disable SchRev\
			TypeSch:Connect(wx.wxEVT_COMMAND_CHOICE_SELECTED,function(event) \
				setfenv(1,package.loaded[modname])\
				if TypeSch:GetString(TypeSch:GetSelection()) == \"Estimate\" or TypeSch:GetString(TypeSch:GetSelection()) == \"Revisions\" then\
					SchRev:Enable(true)\
				else\
					SchRev:Enable(false)\
				end\
			end \
			)\
\
			local DateRangeLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, \"Select Date Ranges\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\
			duSizer:Add(DateRangeLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			-- Date Ranges Control\
			schDateRanges = DateRangeCtrl(SchPanel,\"ScheduleRange\",true,\"Date Ranges\") \
			duSizer:Add(schDateRanges.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
			\
			SchPanelSizer:Add(duSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
\
			-- Now add the Boolean Control\
			local getSchUnit = function()\
				-- Get the full schedule boolean unit\
				local unit = TypeMatch:GetString(TypeMatch:GetSelection())..\",\"..TypeSch:GetString(TypeSch:GetSelection())\
				if SchRev:IsEnabled() then\
					if SchRev:GetValue() == \"Latest\" then\
						unit = unit..\"(L)\"\
					else\
						unit = unit..\"(\"..tostring(SchRev:GetValue())..\")\"\
					end\
				end\
				schDateRanges:UpdateFilter()\
				if not filter.ScheduleRange then\
					unit = nil\
				else\
					unit = unit..\",\"..filter.ScheduleRange\
				end\
				return unit\
			end \
\
			SchBoolCtrl = BooleanTreeCtrl(SchPanel,SchPanelSizer,getSchUnit, \"Schedules\")\
\
			\
\
			SchPanel:SetSizer(SchPanelSizer)\
			SchPanelSizer:SetSizeHints(SchPanel)\
		MainBook:AddPage(SchPanel, \"Schedules\")\
		\
		-- Custom Script Entry Page\
		ScriptPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\
			local ScriptPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL) \
			\
			-- Text Instruction\
			local InsLabel = wx.wxStaticText(ScriptPanel, wx.wxID_ANY, \"Enter a custom script to filte out tasks additional to the Filter set in the form. The task would be present in the environment in the table called 'task'. Apart from that the environment is what is setup in Globals.safeenv. The 'result' variable should be updated to true if pass or false if does not pass.\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\
			InsLabel:Wrap(frame:GetSize():GetWidth()-25)\
			ScriptPanelSizer:Add(InsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
			ScriptBox = wx.wxTextCtrl(ScriptPanel, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)\
			ScriptPanelSizer:Add(ScriptBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\
			\
\
			ScriptPanel:SetSizer(ScriptPanelSizer)\
			ScriptPanelSizer:SetSizeHints(ScriptPanel)\
		MainBook:AddPage(ScriptPanel, \"Custom Script\")\
		\
\
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	local ButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\
	ToBaseButton = wx.wxButton(frame, wx.wxID_ANY, \"Current to Base\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
	ButtonSizer:Add(ToBaseButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	CancelButton = wx.wxButton(frame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
	ButtonSizer:Add(CancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	ApplyButton = wx.wxButton(frame, wx.wxID_ANY, \"Apply\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\
	ButtonSizer:Add(ApplyButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	MainSizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\
	frame:SetSizer(MainSizer)\
	--MainSizer:SetSizeHints(frame)\
	\
	-- Connect event handlers to the buttons\
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function (event)\
			setfenv(1,package.loaded[modname])		\
			frame:Close()\
			callBack(nil)\
		end\
	)\
	\
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,\
		function (event)\
			setfenv(1,package.loaded[modname])		\
			event:Skip()\
			callBack(nil)\
		end\
	)\
\
	ApplyButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			local f = synthesizeFilter()\
			if not f then\
				return\
			end\
			--print(tableToString(f))\
			frame:Close()\
			callBack(f)\
		end		\
	)\
\
--	Connect(wxID_ANY,wxEVT_CLOSE_WINDOW,(wxObjectEventFunction)&CriteriaFrame::OnClose);\
\
	-- Task Selection/Clear button press event\
	SelTaskButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, SelTaskPress)\
	ClearTaskButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\
		function (event)\
			setfenv(1,package.loaded[modname])\
			filter.TasksSet = nil\
			FilterTask:SetLabel(\"No Task Selected\")\
		end\
	)\
	\
	frame:Connect(wx.wxEVT_SIZE,\
		function(event)\
			setfenv(1,package.loaded[modname])\
			InsLabel:Wrap(frame:GetSize():GetWidth())\
			event:Skip()\
		end\
	)\
\
	-- Toolbar button events\
	frame:Connect(ID_LOAD,wx.wxEVT_COMMAND_MENU_SELECTED,loadFilter)\
	frame:Connect(ID_SAVE,wx.wxEVT_COMMAND_MENU_SELECTED,saveFilter)\
	\
    frame:Layout() -- help sizing the windows before being shown\
    frame:Show(true)\
    setfilter(MainFilter)\
end		-- function filterFormActivate(parent) ends\
"
__MANY2ONEFILES['LuaXml']="require(\"LuaXML_lib\")\
\
local base = _G\
local xml = xml\
module(\"xml\")\
\
-- symbolic name for tag index, this allows accessing the tag by var[xml.TAG]\
TAG = 0\
\
-- sets or returns tag of a LuaXML object\
function tag(var,tag)\
  if base.type(var)~=\"table\" then return end\
  if base.type(tag)==\"nil\" then \
    return var[TAG]\
  end\
  var[TAG] = tag\
end\
\
-- creates a new LuaXML object either by setting the metatable of an existing Lua table or by setting its tag\
function new(arg)\
  if base.type(arg)==\"table\" then \
    base.setmetatable(arg,{__index=xml, __tostring=xml.str})\
	return arg\
  end\
  local var={}\
  base.setmetatable(var,{__index=xml, __tostring=xml.str})\
  if base.type(arg)==\"string\" then var[TAG]=arg end\
  return var\
end\
\
-- appends a new subordinate LuaXML object to an existing one, optionally sets tag\
function append(var,tag)\
  if base.type(var)~=\"table\" then return end\
  local newVar = new(tag)\
  var[#var+1] = newVar\
  return newVar\
end\
\
-- converts any Lua var into an XML string\
function str(var,indent,tagValue)\
  if base.type(var)==\"nil\" then return end\
  local indent = indent or 0\
  local indentStr=\"\"\
  for i = 1,indent do indentStr=indentStr..\"  \" end\
  local tableStr=\"\"\
  \
  if base.type(var)==\"table\" then\
    local tag = var[0] or tagValue or base.type(var)\
    local s = indentStr..\"<\"..tag\
    for k,v in base.pairs(var) do -- attributes \
      if base.type(k)==\"string\" then\
        if base.type(v)==\"table\" and k~=\"_M\" then --  otherwise recursiveness imminent\
          tableStr = tableStr..str(v,indent+1,k)\
        else\
          s = s..\" \"..k..\"=\\\"\"..encode(base.tostring(v))..\"\\\"\"\
        end\
      end\
    end\
    if #var==0 and #tableStr==0 then\
      s = s..\" />\\n\"\
    elseif #var==1 and base.type(var[1])~=\"table\" and #tableStr==0 then -- single element\
      s = s..\">\"..encode(base.tostring(var[1]))..\"</\"..tag..\">\\n\"\
    else\
      s = s..\">\\n\"\
      for k,v in base.ipairs(var) do -- elements\
        if base.type(v)==\"string\" then\
          s = s..indentStr..\"  \"..encode(v)..\" \\n\"\
        else\
          s = s..str(v,indent+1)\
        end\
      end\
      s=s..tableStr..indentStr..\"</\"..tag..\">\\n\"\
    end\
    return s\
  else\
    local tag = base.type(var)\
    return indentStr..\"<\"..tag..\"> \"..encode(base.tostring(var))..\" </\"..tag..\">\\n\"\
  end\
end\
\
\
-- saves a Lua var as xml file\
function save(var,filename)\
  if not var then return end\
  if not filename or #filename==0 then return end\
  local file = base.io.open(filename,\"w\")\
  file:write(\"<?xml version=\\\"1.0\\\"?>\\n<!-- file \\\"\",filename, \"\\\", generated by LuaXML -->\\n\\n\")\
  file:write(str(var))\
  base.io.close(file)\
end\
\
\
-- recursively parses a Lua table for a substatement fitting to the provided tag and attribute\
function find(var, tag, attributeKey,attributeValue)\
  -- check input:\
  if base.type(var)~=\"table\" then return end\
  if base.type(tag)==\"string\" and #tag==0 then tag=nil end\
  if base.type(attributeKey)~=\"string\" or #attributeKey==0 then attributeKey=nil end\
  if base.type(attributeValue)==\"string\" and #attributeValue==0 then attributeValue=nil end\
  -- compare this table:\
  if tag~=nil then\
    if var[0]==tag and ( attributeValue == nil or var[attributeKey]==attributeValue ) then\
      base.setmetatable(var,{__index=xml, __tostring=xml.str})\
      return var\
    end\
  else\
    if attributeValue == nil or var[attributeKey]==attributeValue then\
      base.setmetatable(var,{__index=xml, __tostring=xml.str})\
      return var\
    end\
  end\
  -- recursively parse subtags:\
  for k,v in base.ipairs(var) do\
    if base.type(v)==\"table\" then\
      local ret = find(v, tag, attributeKey,attributeValue)\
      if ret ~= nil then return ret end\
    end\
  end\
end\
"
__MANY2ONEFILES['DataHandler']="Karm.TaskObject = {}\
Karm.TaskObject.__index = Karm.TaskObject\
-- Table to store the Core values\
Karm.Core.TaskObject = {}\
--[[\
do\
	local KarmMeta = {__metatable = \"Hidden, Do not change!\"}\
	KarmMeta.__newindex = function(tab,key,val)\
		if Karm.TaskObject.key and not Karm.Core.TaskObject.key then\
			Karm.Core.TaskObject.key = Karm.TaskObject.key\
		end\
		rawset(Karm.TaskObject,key,val)\
	end\
	setmetatable(Karm.TaskObject,KarmMeta)\
end\
]]\
Karm.Utility = {}\
-- Table to store the Core values\
Karm.Core.Utility = {}\
--[[\
do\
	local KarmMeta = {__metatable = \"Hidden, Do not change!\"}\
	KarmMeta.__newindex = function(tab,key,val)\
		if Karm.Utility.key and not Karm.Core.Utility.key then\
			Karm.Core.Utility.key = Karm.Utility.key\
		end\
		rawset(Karm.Utility,key,val)\
	end\
	setmetatable(Karm.Utility,KarmMeta)\
end\
]]\
-- Task structure\
-- Task.\
--	Planning\
--	[0] = Task\
-- 	SporeFile\
--	Title\
--	Modified\
--	DBDATA\
--	TaskID\
--	Start\
--	Fin\
--	Private\
--	Who\
--	Access\
--	Assignee\
--	Status\
--	Parent = Pointer to the Task to which this is a sub task\
--	Priority\
--	Due\
--	Comments\
--	Cat\
--	SubCat\
--	Tags\
--	Schedules.\
--		[0] = \"Schedules\"\
--		Estimate.\
--			[0] = \"Estimate\"\
--			count\
--			[i] = \
--		Commit.\
--			[0] = \"Commit\"\
--		Revs\
--		Actual\
--	SubTasks.\
--		[0] = \"SubTasks\"\
--		parent  = pointer to the array containing the list of tasks having the task whose SubTask this is \
--		tasks = count of number of subtasks\
--		[i] = Task table like this one repeated for sub tasks\
function Karm.TaskObject.getSummary(task)\
	if task then\
		local taskSummary = \"\"\
		if task.TaskID then\
			taskSummary = \"ID: \"..task.TaskID\
		end\
		if task.Title then\
			taskSummary = taskSummary..\"\\nTITLE: \"..task.Title\
		end\
		if task.Start then\
			taskSummary = taskSummary..\"\\nSTART DATE: \"..task.Start\
		end\
		if task.Fin then\
			taskSummary = taskSummary..\"\\nFINISH DATE: \"..task.Fin\
		end\
		if task.Due then\
			taskSummary = taskSummary..\"\\nDUE DATE: \"..task.Due\
		end\
		if task.Status then\
			taskSummary = taskSummary..\"\\nSTATUS: \"..task.Status\
		end\
		-- Responsible People\
		if task.Who then\
			taskSummary = taskSummary..\"\\nPEOPLE: \"\
			local ACT = \"\"\
			local INACT = \"\"\
			for i=1,task.Who.count do\
				if string.upper(task.Who[i].Status) == \"ACTIVE\" then\
					ACT = ACT..\",\"..task.Who[i].ID\
				else\
					INACT = INACT..\",\"..task.Who[i].ID\
				end\
			end\
			if #ACT > 0 then\
				taskSummary = taskSummary..\"\\n   ACTIVE: \"..string.sub(ACT,2,-1)\
			end\
			if #INACT > 0 then\
				taskSummary = taskSummary..\"\\n   INACTIVE: \"..string.sub(INACT,2,-1)\
			end\
		end\
		if task.Access then\
			taskSummary = taskSummary..\"\\nLOCKED: YES\"\
			local RA = \"\"\
			local RWA = \"\"\
			for i = 1,task.Access.count do\
				if string.upper(task.Access[i].Status) == \"READ ONLY\" then\
					RA = RA..\",\"..task.Access[i].ID\
				else\
					RWA = RWA..\",\"..task.Access[i].ID\
				end\
			end\
			if #RA > 0 then\
				taskSummary = taskSummary..\"\\n   READ ACCESS PEOPLE: \"..string.sub(RA,2,-1)\
			end\
			if #RWA > 0 then\
				taskSummary = taskSummary..\"\\n   READ/WRITE ACCESS PEOPLE: \"..string.sub(RWA,2,-1)\
			end\
		end\
		if task.Assignee then\
			taskSummary = taskSummary..\"\\nASSIGNEE: \"\
			for i = 1,#task.Assignee do\
				taskSummary = taskSummary..task.Assignee[i].ID..\",\"\
			end\
			taskSummary = taskSummary:sub(1,-2)\
		end\
		if task.Priority then\
			taskSummary = taskSummary..\"\\nPRIORITY: \"..task.Priority\
		end\
		if task.Private then\
			taskSummary = taskSummary..\"\\nPRIVATE TASK\"\
		end\
		if task.Cat then\
			taskSummary = taskSummary..\"\\nCATEGORY: \"..task.Cat\
		end\
		if task.SubCat then\
			taskSummary = taskSummary..\"\\nSUB-CATEGORY: \"..task.SubCat\
		end\
		if task.Tags then\
			taskSummary = taskSummary..\"\\nTAGS: \"\
			for i = 1,#task.Tags do\
				taskSummary = taskSummary..task.Tags[i]..\",\"\
			end\
			taskSummary = taskSummary:sub(1,-2)\
		end\
		if task.Comments then\
			taskSummary = taskSummary..\"\\nCOMMENTS:\\n\"..task.Comments\
		end\
		return taskSummary\
	else\
		return \"No Task Selected\"\
	end\
end\
\
function Karm.validateSpore(Spore)\
	if not Spore then\
		return nil\
	elseif type(Spore) ~= \"table\" then\
		return nil\
	elseif Spore[0] ~= \"Task_Spore\" then\
		return nil\
	end\
	return true\
end\
\
\
function Karm.TaskObject.getWorkDoneDates(task)\
	if task.Schedules then\
		if task.Schedules.Actual then\
			local dateList = {}\
			for i = 1,#task.Schedules[\"Actual\"][1].Period do\
				dateList[#dateList + 1] = task.Schedules[\"Actual\"][1].Period[i].Date\
			end		-- for i = 1,#task.Schedules[\"Actual\"][1].Period do ends\
			dateList.typeSchedule = \"Actual\"\
			dateList.index = 1\
			return dateList\
		else \
			return nil\
		end\
	else \
		return nil		\
	end		-- if task.Schedules then ends\
end\
-- Function to get the list of dates in the latest schedule of the task.\
-- if planning == true then the planning schedule dates are returned\
function Karm.TaskObject.getLatestScheduleDates(task,planning)\
	local typeSchedule, index\
	local dateList = {}\
	if planning then\
		if task.Planning and task.Planning.Period then\
			for i = 1,#task.Planning.Period do\
				dateList[#dateList + 1] = task.Planning.Period[i].Date\
			end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends\
			dateList.typeSchedule = task.Planning.Type\
			dateList.index = task.Planning.index\
			return dateList\
		else\
			return nil\
		end\
	else\
		if task.Schedules then\
			-- Find the latest schedule in the task here\
			if string.upper(task.Status) == \"DONE\" and task.Schedules.Actual then\
				typeSchedule = \"Actual\"\
				index = 1\
			elseif task.Schedules.Revs then\
				-- Actual is not the latest one but Revision is \
				typeSchedule = \"Revs\"\
				index = task.Schedules.Revs.count\
			elseif task.Schedules.Commit then\
				-- Actual and Revisions don't exist but Commit does\
				typeSchedule = \"Commit\"\
				index = 1\
			elseif task.Schedules.Estimate then\
				-- The latest is Estimate\
				typeSchedule = \"Estimate\"\
				index = task.Schedules.Estimate.count\
			else\
				-- task.Schedules can exist if only Actual exists  but task is not DONE yet\
				return nil\
			end\
			-- Now we have the latest schedule type in typeSchedule and the index of it in index\
			for i = 1,#task.Schedules[typeSchedule][index].Period do\
				dateList[#dateList + 1] = task.Schedules[typeSchedule][index].Period[i].Date\
			end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends\
			dateList.typeSchedule = typeSchedule\
			dateList.index = index\
			return dateList\
		else\
			return nil\
		end\
	end		-- if planning then ends\
end\
\
-- Function to convert a table to a string\
-- Metatables not followed\
-- Unless key is a number it will be taken and converted to a string\
function Karm.Utility.tableToString(t)\
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)\
	rL[rL.cL] = {}\
	do\
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)\
		rL[rL.cL].str = \"{\"\
		rL[rL.cL].t = t\
		while true do\
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)\
			rL[rL.cL]._var = k\
			if not k and rL.cL == 1 then\
				break\
			elseif not k then\
				-- go up in recursion level\
				if string.sub(rL[rL.cL].str,-1,-1) == \",\" then\
					rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)\
				end\
				--print(\"GOING UP:     \"..rL[rL.cL].str..\"}\")\
				rL[rL.cL-1].str = rL[rL.cL-1].str..rL[rL.cL].str..\"}\"\
				rL.cL = rL.cL - 1\
				rL[rL.cL+1] = nil\
				rL[rL.cL].str = rL[rL.cL].str..\",\"\
			else\
				-- Handle the key and value here\
				if type(k) == \"number\" then\
					rL[rL.cL].str = rL[rL.cL].str..\"[\"..tostring(k)..\"]=\"\
				else\
					rL[rL.cL].str = rL[rL.cL].str..tostring(k)..\"=\"\
				end\
				if type(v) == \"table\" then\
					-- Check if this is not a recursive table\
					local goDown = true\
					for i = 1, rL.cL do\
						if v==rL[i].t then\
							-- This is recursive do not go down\
							goDown = false\
							break\
						end\
					end\
					if goDown then\
						-- Go deeper in recursion\
						rL.cL = rL.cL + 1\
						rL[rL.cL] = {}\
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)\
						rL[rL.cL].str = \"{\"\
						rL[rL.cL].t = v\
						--print(\"GOING DOWN:\",k)\
					else\
						rL[rL.cL].str = rL[rL.cL].str..\"\\\"\"..tostring(v)..\"\\\"\"\
						rL[rL.cL].str = rL[rL.cL].str..\",\"\
						--print(k,\"=\",v)\
					end\
				elseif type(v) == \"number\" then\
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)\
					rL[rL.cL].str = rL[rL.cL].str..\",\"\
					--print(k,\"=\",v)\
				else\
					rL[rL.cL].str = rL[rL.cL].str..string.format(\"%q\",tostring(v))\
					rL[rL.cL].str = rL[rL.cL].str..\",\"\
					--print(k,\"=\",v)\
				end		-- if type(v) == \"table\" then ends\
			end		-- if not rL[rL.cL]._var and rL.cL == 1 then ends\
		end		-- while true ends here\
	end		-- do ends\
	if string.sub(rL[rL.cL].str,-1,-1) == \",\" then\
		rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)\
	end\
	rL[rL.cL].str = rL[rL.cL].str..\"}\"\
	return rL[rL.cL].str\
end\
\
-- Creates lua code for a table which when executed will create a table t0 which would be the same as the originally passed table\
-- Handles the following types for keys and values:\
-- Keys: Number, String, Table\
-- Values: Number, String, Table, Boolean\
-- It also handles recursive and interlinked tables to recreate them back\
function Karm.Utility.tableToString2(t)\
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)\
	rL[rL.cL] = {}\
	local tabIndex = {}	-- Table to store a list of tables indexed into a string and their variable name\
	local latestTab = 0\
	do\
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)\
		rL[rL.cL].str = \"t0={}\"	-- t0 would be the main table\
		rL[rL.cL].t = t\
		rL[rL.cL].tabIndex = 0\
		tabIndex[t] = rL[rL.cL].tabIndex\
		while true do\
			local key\
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)\
			rL[rL.cL]._var = k\
			if not k and rL.cL == 1 then\
				break\
			elseif not k then\
				-- go up in recursion level\
				--print(\"GOING UP:     \"..rL[rL.cL].str..\"}\")\
				rL[rL.cL-1].str = rL[rL.cL-1].str..\"\\n\"..rL[rL.cL].str\
				rL.cL = rL.cL - 1\
				if rL[rL.cL].vNotDone then\
					-- This was a key recursion so add the key string and then doV\
					key = \"t\"..rL[rL.cL].tabIndex..\"[t\"..tostring(rL[rL.cL+1].tabIndex)..\"]\"\
					rL[rL.cL].str = rL[rL.cL].str..\"\\n\"..key..\"=\"\
					v = rL[rL.cL].vNotDone\
				end\
				rL[rL.cL+1] = nil\
			else\
				-- Handle the key and value here\
				if type(k) == \"number\" then\
					key = \"t\"..rL[rL.cL].tabIndex..\"[\"..tostring(k)..\"]\"\
					rL[rL.cL].str = rL[rL.cL].str..\"\\n\"..key..\"=\"\
				elseif type(k) == \"string\" then\
					key = \"t\"..rL[rL.cL].tabIndex..\".\"..tostring(k)\
					rL[rL.cL].str = rL[rL.cL].str..\"\\n\"..key..\"=\"\
				else\
					-- Table key\
					-- Check if the table already exists\
					if tabIndex[k] then\
						key = \"t\"..rL[rL.cL].tabIndex..\"[t\"..tabIndex[k]..\"]\"\
						rL[rL.cL].str = rL[rL.cL].str..\"\\n\"..key..\"=\"\
					else\
						-- Go deeper to stringify this table\
						latestTab = latestTab + 1\
						rL[rL.cL].str = rL[rL.cL].str..\"\\nt\"..tostring(latestTab)..\"={}\"	-- New table\
						rL[rL.cL].vNotDone = v\
						rL.cL = rL.cL + 1\
						rL[rL.cL] = {}\
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(k)\
						rL[rL.cL].tabIndex = latestTab\
						rL[rL.cL].t = k\
						rL[rL.cL].str = \"\"\
						tabIndex[k] = rL[rL.cL].tabIndex\
					end		-- if tabIndex[k] then ends\
				end		-- if type(k)ends\
			end		-- if not k and rL.cL == 1 then ends\
			if key then\
				rL[rL.cL].vNotDone = nil\
				if type(v) == \"table\" then\
					-- Check if this table is already indexed\
					if tabIndex[v] then\
						rL[rL.cL].str = rL[rL.cL].str..\"t\"..tabIndex[v]\
					else\
						-- Go deeper in recursion\
						latestTab = latestTab + 1\
						rL[rL.cL].str = rL[rL.cL].str..\"{}\" \
						rL[rL.cL].str = rL[rL.cL].str..\"\\nt\"..tostring(latestTab)..\"=\"..key	-- New table\
						rL.cL = rL.cL + 1\
						rL[rL.cL] = {}\
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)\
						rL[rL.cL].tabIndex = latestTab\
						rL[rL.cL].t = v\
						rL[rL.cL].str = \"\"\
						tabIndex[v] = rL[rL.cL].tabIndex\
						--print(\"GOING DOWN:\",k)\
					end\
				elseif type(v) == \"number\" then\
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)\
					--print(k,\"=\",v)\
				elseif type(v) == \"boolean\" then\
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)				\
				else\
					rL[rL.cL].str = rL[rL.cL].str..string.format(\"%q\",tostring(v))\
					--print(k,\"=\",v)\
				end		-- if type(v) == \"table\" then ends\
			end		-- if doV then ends\
		end		-- while true ends here\
	end		-- do ends\
	return rL[rL.cL].str\
end\
\
function Karm.Utility.combineDateRanges(range1,range2)\
	local comp = Karm.Utility.compareDateRanges(range1,range2)\
\
	local strt1,fin1 = string.match(range1,\"(.-)%-(.*)\")\
	local strt2,fin2 = string.match(range2,\"(.-)%-(.*)\")\
	\
	strt1 = Karm.Utility.toXMLDate(strt1)\
	local idate = Karm.Utility.XMLDate2wxDateTime(strt1)\
	idate = idate:Subtract(wx.wxDateSpan(0,0,0,1))\
	local strt1m1 = Karm.Utility.toXMLDate(idate:Format(\"%m/%d/%Y\"))\
	\
	fin1 = Karm.Utility.toXMLDate(fin1)\
	idate = Karm.Utility.XMLDate2wxDateTime(fin1)\
	idate = idate:Add(wx.wxDateSpan(0,0,0,1))\
	local fin1p1 = Karm.Utility.toXMLDate(idate:Format(\"%m/%d/%Y\"))\
\
	strt2 = Karm.Utility.toXMLDate(strt2)\
\
	fin2 = Karm.Utility.toXMLDate(fin2)\
\
	if comp == 1 then\
		return range1\
	elseif comp==2 then\
		-- range1 lies entirely before range2\
		error(\"Disjoint ranges\",2)\
	elseif comp==3 then\
		-- range1 pre-overlaps range2\
		return string.sub(strt1,6,7)..\"/\"..string.sub(strt1,-2,-1)..\"/\"..string.sub(strt1,1,4)..\"-\"..\
			string.sub(fin2,6,7)..\"/\"..string.sub(fin2,-2,-1)..\"/\"..string.sub(fin2,1,4)\
	elseif comp==4 then\
		-- range1 lies entirely inside range2\
		return range2\
	elseif comp==5 then\
		-- range1 post overlaps range2\
		return string.sub(strt2,6,7)..\"/\"..string.sub(strt2,-2,-1)..\"/\"..string.sub(strt2,1,4)..\"-\"..\
			string.sub(fin1,6,7)..\"/\"..string.sub(fin1,-2,-1)..\"/\"..string.sub(fin1,1,4)\
	elseif comp==6 then\
		-- range1 lies entirely after range2\
		error(\"Disjoint ranges\",2)\
	elseif comp==7 then\
		-- range2 lies entirely inside range1\
			return range1\
	end		\
end\
\
function Karm.Utility.XMLDate2wxDateTime(XMLdate)\
	local map = {\
		[1] = wx.wxDateTime.Jan,\
		[2] = wx.wxDateTime.Feb,\
		[3] = wx.wxDateTime.Mar,\
		[4] = wx.wxDateTime.Apr,\
		[5] = wx.wxDateTime.May,\
		[6] = wx.wxDateTime.Jun,\
		[7] = wx.wxDateTime.Jul,\
		[8] = wx.wxDateTime.Aug,\
		[9] = wx.wxDateTime.Sep,\
		[10] = wx.wxDateTime.Oct,\
		[11] = wx.wxDateTime.Nov,\
		[12] = wx.wxDateTime.Dec\
	}\
	return wx.wxDateTimeFromDMY(tonumber(string.sub(XMLdate,-2,-1)),map[tonumber(string.sub(XMLdate,6,7))],tonumber(string.sub(XMLdate,1,4)))\
end\
\
--****f* Karm/compareDateRanges\
-- FUNCTION\
-- Function to compare 2 date ranges\
-- \
-- INPUT\
-- o range1 -- Date Range 1 eg. 2/25/2012-2/27/2012\
-- o range2 -- Date Range 2 eg. 2/25/2012-3/27/2012\
-- \
-- RETURNS\
-- o 1 -- If date ranges identical\
-- o 2 -- If range1 lies entirely before range2\
-- o 3 -- If range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2 and not condition 2\
-- o 4 -- If range1 lies entirely inside range2\
-- o 5 -- If range1 post overlaps range2 i.e. start date of range 1 >= start date of range 2 and start date of range 1 - 1 day <= end date of range 2 and not condition 4 \
-- o 6 -- If range1 lies entirely after range2\
-- o 7 -- If range2 lies entirely inside range1\
-- o nil -- for error\
--\
-- SOURCE\
function Karm.Utility.compareDateRanges(range1,range2)\
--@@END@@\
	if not(range1 and range2) or range1==\"\" or range2==\"\" then\
		error(\"Expected a valid date range.\",2)\
	end\
	\
	if range1 == range2 then\
		--  date ranges identical\
		return 1\
	end\
	\
	local strt1,fin1 = string.match(range1,\"(.-)%-(.*)\")\
	local strt2,fin2 = string.match(range2,\"(.-)%-(.*)\")\
	\
	strt1 = Karm.Utility.toXMLDate(strt1)\
	local idate = Karm.Utility.XMLDate2wxDateTime(strt1)\
	idate = idate:Subtract(wx.wxDateSpan(0,0,0,1))\
	local strt1m1 = Karm.Utility.toXMLDate(idate:Format(\"%m/%d/%Y\"))\
	\
	fin1 = Karm.Utility.toXMLDate(fin1)\
	idate = Karm.Utility.XMLDate2wxDateTime(fin1)\
	idate = idate:Add(wx.wxDateSpan(0,0,0,1))\
	local fin1p1 = Karm.Utility.toXMLDate(idate:Format(\"%m/%d/%Y\"))\
	\
	strt2 = Karm.Utility.toXMLDate(strt2)\
	\
	fin2 = Karm.Utility.toXMLDate(fin2)\
	\
	if strt1>fin1 or strt2>fin2 then\
		error(\"Range given is not valid. Start date should be less than finish date.\",2)\
	end\
	\
	if fin1p1<strt2 then\
		-- range1 lies entirely before range2\
		return 2\
	elseif fin1<=fin2 and strt1<strt2 then\
		-- range1 pre-overlaps range2\
		return 3\
	elseif strt1>strt2 and fin1<fin2 then\
		-- range1 lies entirely inside range2\
		return 4\
	elseif strt1m1<=fin2 and strt1>=strt2 then\
		-- range1 post overlaps range2\
		return 5\
	elseif strt1m1>fin2 then\
		-- range1 lies entirely after range2\
		return 6\
	elseif strt1<strt2 and fin1>fin2 then\
		-- range2 lies entirely inside range1\
		return 7\
	end\
end\
--****f* Karm/ToXMLDate\
-- FUNCTION\
-- Function to convert display format date to XML format date YYYY-MM-DD\
-- display date format is MM/DD/YYYY\
--\
-- INPUT\
-- o displayDate -- String variable containing the date string as MM/DD/YYYY\
--\
-- RETURNS\
-- The date as a string compliant to XML date format YYYY-MM-DD\
--\
-- SOURCE\
function Karm.Utility.toXMLDate(displayDate)\
--@@END@@\
\
    local exYear, exMonth, exDate\
    local count = 1\
    for num in string.gmatch(displayDate,\"%d+\") do\
    	if count == 1 then\
    		-- this is month\
    		exMonth = num\
	    	if #exMonth == 1 then\
        		exMonth = \"0\" .. exMonth\
        	end\
        elseif count==2 then\
        	-- this is the date\
        	exDate = num\
        	if #exDate == 1 then\
        		exDate = \"0\" .. exDate\
        	end\
        elseif count== 3 then\
        	-- this is the year\
        	exYear = num\
        	if #exYear == 1 then\
        		exYear = \"000\" .. exYear\
        	elseif #exYear == 2 then\
        		exYear = \"00\" .. exYear\
        	elseif #exYear == 3 then\
        		exYear = \"0\" .. exYear\
        	end\
        end\
        count = count + 1\
	end    \
    return exYear .. \"-\" .. exMonth .. \"-\" .. exDate\
end\
\
function Karm.Utility.getWeekDay(xmlDate)\
	if #xmlDate ~= 10 then\
		error(\"Expected XML Date in the form YYYY-MM-DD\",2)\
	end\
	local WeekDays = {\"Sunday\",\"Monday\",\"Tuesday\",\"Wednesday\",\"Thursday\",\"Friday\",\"Saturday\"}\
	-- Using the Gauss Formula\
	-- http://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week#Gaussian_algorithm\
	local d = tonumber(xmlDate:sub(-2,-1))\
	local m = tonumber(xmlDate:sub(6,7))\
	m = (m + 9)%12 + 1\
	local Y\
	if m > 10 then\
		Y = string.match(tostring(tonumber(xmlDate:sub(1,4)) - 1),\"%d+\")\
		Y = string.rep(\"0\",4-#Y)..Y\
	else\
		Y = xmlDate:sub(1,4)\
	end\
	local y = tonumber(Y:sub(-2,-1))\
	local c = tonumber(Y:sub(1,2))\
	local w = (d + (2.6*m-0.2)-(2.6*m-0.2)%1 + y + (y/4)-(y/4)%1 + (c/4)-(c/4)%1-2*c)%7+1\
	return WeekDays[w]\
end\
\
function Karm.Utility.addItemToArray(item,array)\
	local pos = 0\
	for i = 1,#array do\
		if array[i] == item  then\
			return array\
		end\
		if array[i]>item then\
			pos = i\
			break\
		end\
	end\
	if pos == 0 then\
		-- place item in the end\
		array[#array+1] = item\
		return array\
	end\
	local newarray = {}\
	for i = 1,pos-1 do\
		newarray[i] = array[i]\
	end\
	newarray[pos] = item\
	for i = pos,#array do\
		newarray[i+1] = array[i]\
	end\
	return newarray\
end\
\
function Karm.TaskObject.CheckSporeIntegrity(task, Spore)\
	if not task and not Spore then\
		error(\"Need a task or a Spore object to check the spore integrity\", 2)\
	end\
	if task and getmetatable(task) ~= Karm.TaskObject then\
		error(\"Need a valid task object to check Spore integrity.\", 2)\
	end\
	local spore \
	if task then\
		if not task.Parent then\
			spore = task.SubTasks.parent\
		else\
			spore = task.Parent.SubTasks.parent\
			while spore.parent do\
				spore = spore.parent\
			end\
		end\
	else\
		spore = Spore\
	end\
	local integrityError = {}\
	local checkFunc = function(task)\
		if task.Title == \"Karm\" then\
			local x = 1\
		end\
		local pa = task.Parent\
		local index\
		for i = 1,#pa.SubTasks do\
			if pa.SubTasks[i] == task then\
				index = i\
				break\
			end\
		end\
		if not index then\
			integrityError[#integrityError + 1] = {Task = task, Error = \"Parent mismatch\"}\
			return\
		end\
		if (index > 1 and pa.SubTasks[index - 1] ~= task.Previous) or (index == 1 and task.Previous) then\
			integrityError[#integrityError + 1] = {Task = task, Error = \"Previous mismatch\"}\
		end\
		if (index < #pa.SubTasks and pa.SubTasks[index + 1] ~= task.Next) or (index == #pa.SubTasks and task.Next) then\
			integrityError[#integrityError + 1] = {Task = task, Error = \"Next mismatch\"}\
		end		\
		-- Check parents of all subTasks\
		if task.SubTasks then\
			for i = 1,#task.SubTasks do\
				if task.SubTasks[i].Parent ~= task then\
					integrityError[#integrityError + 1] = {Task = task.SubTasks[i], Error = \"Parent mismatch\"}\
				end\
			end\
			if task.SubTasks.parent ~= task.Parent.SubTasks then\
				integrityError[#integrityError + 1] = {Task = task, Error = \"SubTasks Parent mismatch\"}\
			end\
		end\
	end\
	for i = 1,#spore do\
		if (i > 1  and spore[i-1] ~= spore[i].Previous) or (i == 1 and spore[i].Previous) then\
			integrityError[#integrityError + 1] = {Task = spore[i], Error = \"Previous mismatch\"}\
		end\
		if (i < #spore and spore[i + 1] ~= spore[i].Next) or (i == #spore and spore[i].Next) then\
			integrityError[#integrityError + 1] = {Task = spore[i], Error = \"Next mismatch\"}\
		end		\
		spore[i]:applyFuncHier(checkFunc, nil, true)\
	end\
	return integrityError\
end\
\
-- Function to apply a function to a task and its hierarchy\
-- The function should have the task as the 1st argument \
-- and whatever it returns is passed to it it as the 2nd argument in the next call to it with the next task\
-- In the 1st call the second argument is passed if it is given as the 3rd argument to this function\
-- The last return from the function is returned by this function\
-- if omitTask is true then the func is not run for the task itself and it starts from the subTasks\
function Karm.TaskObject.applyFuncHier(task, func, initialValue, omitTask)\
	local passedVar	= initialValue	-- Variable passed to the function\
	if not omitTask then\
		passedVar = func(task,initialValue)\
	end\
	if task.SubTasks then\
		-- Traverse the task hierarchy here\
		local hier = task.SubTasks\
		local hierCount = {}\
		hierCount[hier] = 0\
		while hierCount[hier] < #hier or hier.parent do\
			if not(hierCount[hier] < #hier) then\
				if hier == task.SubTasks then\
					-- Do not go above the passed task\
					break\
				end \
				hier = hier.parent\
			else\
				-- Increment the counter\
				hierCount[hier] = hierCount[hier] + 1\
				passedVar = func(hier[hierCount[hier]],passedVar)\
				if hier[hierCount[hier]].SubTasks then\
					-- This task has children so go deeper in the hierarchy\
					hier = hier[hierCount[hier]].SubTasks\
					hierCount[hier] = 0\
				end\
			end\
		end		-- while hierCount[hier] < #hier or hier.parent do ends here\
	end\
	return passedVar\
end\
\
-- To find out if a task is under the sub task tree of ancestor\
function Karm.TaskObject.IsUnder(task,ancestor)\
	if task==ancestor then\
		return true\
	end\
	local t = task\
	while t.Parent do\
		t = t.Parent\
		if t == ancestor then\
			return true\
		end\
	end\
end\
\
-- Function to get a next task (from the given task) in the task hierarchy. After all tasks for a spore are finished then it will return a nil\
-- Traversal is in the order as if listing out the tasks for a fully expanded task tree\
function Karm.TaskObject.NextInSequence(task)\
	if not task then\
		error(\"Need a task object to give the next task\", 2)\
	end\
	if not type(task) == \"table\" then\
		error(\"Need a task object to give the next task\", 2)\
	end\
	if task.SubTasks and task.SubTasks[1] then\
		return task.SubTasks[1]\
	end	\
	if task.Next then\
		return task.Next\
	end\
	if task.Parent then\
		local currTask = task.Parent\
		if currTask.Next then\
			return currTask.Next\
		end\
		while currTask.Parent do\
			currTask = currTask.Parent\
			if currTask.Next then\
				return currTask.Next\
			end\
		end\
	end\
end\
\
-- Function to get a next task (from the given task) in the task hierarchy. After all tasks for a spore are finished then it will return a nil\
-- Traversal is in the order as if listing out the tasks for a fully expanded task tree\
function Karm.TaskObject.PreviousInSequence(task)\
	if not task then\
		error(\"Need a task object to give the next task\", 2)\
	end\
	if not type(task) == \"table\" then\
		error(\"Need a task object to give the next task\", 2)\
	end\
	if task.Previous then\
		local currTask = task.Previous\
		while Karm.TaskObject.NextInSequence(currTask) ~= task do\
			currTask = Karm.TaskObject.NextInSequence(currTask)\
		end\
		return currTask\
	end\
	return task.Parent\
end\
\
function Karm.TaskObject.accumulateTaskData(task,Data)\
	Data = Data or {}\
	Data.Who = Data.Who or {}\
	Data.Access = Data.Access or {}\
	Data.Priority = Data.Priority or {}\
	Data.Cat = Data.Cat or {}\
	Data.SubCat = Data.SubCat or {}\
	Data.Tags = Data.Tags or {}\
	-- Who data\
	for i = 1,#task.Who do\
		Data.Who = Karm.Utility.addItemToArray(task.Who[i].ID,Data.Who)\
	end\
	-- Access Data\
	if task.Access then\
		for i = 1,#task.Access do\
			Data.Access = Karm.Utility.addItemToArray(task.Access[i].ID,Data.Access)\
		end\
	end\
	-- Priority Data\
	if task.Priority then\
		Data.Priority = Karm.Utility.addItemToArray(task.Priority,Data.Priority)\
	end			\
	-- Category Data\
	if task.Cat then\
		Data.Cat = Karm.Utility.addItemToArray(task.Cat,Data.Cat)\
	end			\
	-- Sub-Category Data\
	if task.SubCat then\
		Data.SubCat = Karm.Utility.addItemToArray(task.SubCat,Data.SubCat)\
	end			\
	-- Tags Data\
	if task.Tags then\
		for i = 1,#task.Tags do\
			Data.Tags = Karm.Utility.addItemToArray(task.Tags[i],Data.Tags)\
		end\
	end\
	return Data\
end\
\
\
-- Function to collect and return all data from the task heirarchy on the basis of which task filtration criteria can be selected\
function Karm.accumulateTaskDataHier(filterData, taskHier)\
	local hier = taskHier\
	-- Reset the hierarchy if not already done so\
	while hier.parent do\
		hier = hier.parent\
	end\
	for i = 1,#hier do\
		filterData = Karm.TaskObject.applyFuncHier(hier[i],Karm.TaskObject.accumulateTaskData,filterData)\
	end\
end\
\
-- Old version \
--function Karm.accumulateTaskDataHier(filterData, taskHier)\
--	local hier = taskHier\
--	local hierCount = {}\
--	-- Reset the hierarchy if not already done so\
--	while hier.parent do\
--		hier = hier.parent\
--	end\
--	-- Traverse the task hierarchy here\
--	hierCount[hier] = 0\
--	while hierCount[hier] < #hier or hier.parent do\
--		if not(hierCount[hier] < #hier) then\
--			if hier == taskHier then\
--				-- Do not go above the passed task\
--				break\
--			end \
--			hier = hier.parent\
--		else\
--			-- Increment the counter\
--			hierCount[hier] = hierCount[hier] + 1\
--			Karm.TaskObject.accumulateTaskData(hier[hierCount[hier]],filterData)\
--			if hier[hierCount[hier]].SubTasks then\
--				-- This task has children so go deeper in the hierarchy\
--				hier = hier[hierCount[hier]].SubTasks\
--				hierCount[hier] = 0\
--			end\
--		end\
--	end		-- while hierCount[hier] < #hier or hier.parent do ends here\
--end\
\
function Karm.accumulateTaskDataList(filterData,taskList)\
	for i=1,#taskList do\
		Karm.TaskObject.accumulateTaskData(taskList[i],filterData)\
	end\
end\
\
-- Function to make a copy of a task\
-- Each task has at most 9 tables:\
\
-- Who\
-- Access\
-- Assignee\
-- Schedules\
-- Tags\
\
-- Parent\
-- Previous\
-- Next\
-- SubTasks\
-- DBDATA\
-- Planning  \
\
-- 1st 5 are made a copy of\
-- Parent, Next and Previous are the same linked tables\
-- If copySubTasks is true then SubTasks are made a copy as well with the same parameters (in this case Previous and Next are \
--         updated for all the SubTasks and so are the parent of the subtasks) otherwise it is the same linked SubTask table\
-- If removeDBDATA is true then it removes the DBDATA table to make this an individual task otherwise it is the same linked table\
-- Normally the sub-task parents are linked to the tasks from which the hierarchy is being copied over, if keepOldTaskParents is false then all the sub-task parents\
-- in the copied hierarchy (excluding this task) will be updated to point to the copied hierarchy tasks\
-- Planning is not copied over\
function Karm.TaskObject.copy(task, copySubTasks, removeDBDATA,keepOldTaskParents)\
	-- Copied from http://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value\
	local copyTableFunc\
	local function copyTable(t, deep, seen)\
	    seen = seen or {}\
	    if t == nil then return nil end\
	    if seen[t] then return seen[t] end\
	\
	    local nt = {}\
	    for k, v in pairs(t) do\
	        if deep and type(v) == 'table' then\
	            nt[k] = copyTableFunc(v, deep, seen)\
	        else\
	            nt[k] = v\
	        end\
	    end\
	    setmetatable(nt, copyTableFunc(getmetatable(t), deep, seen))\
	    seen[t] = nt\
	    return nt\
	end\
	copyTableFunc = copyTable\
\
	if not task then\
		return\
	end\
	local nTask = {}\
	for k,v in pairs(task) do\
		if k ~= \"Planning\" and not (k == \"DBDATA\" and removeDBDATA)then\
			if k ~= \"Who\" and k ~= \"Schedules\" and k~= \"Tags\" and k ~= \"Access\" and k ~= \"Assignee\" and not (k == \"SubTasks\" and copySubTasks)then\
				nTask[k] = task[k]\
			else\
				if k == \"SubTasks\" then\
					-- This has to be copied task by task\
					local parent\
					if task.Parent then\
						parent = task.Parent.SubTasks\
					else\
						-- Must be a root node in a Spore so take the Spore table as the parent itself\
						parent = task.SubTasks.parent\
					end\
					nTask.SubTasks = {parent = parent, tasks = #task.SubTasks, [0]=\"SubTasks\"}\
					for i = 1,#task.SubTasks do\
						nTask.SubTasks[i] = Karm.TaskObject.copy(task.SubTasks[i],true,removeDBDATA,true)\
						if i == 1  then\
							nTask.SubTasks[1].Previous = nil\
						end\
						if i > 1 then\
							nTask.SubTasks[i].Previous = nTask.SubTasks[i-1]\
							nTask.SubTasks[i-1].Next = nTask.SubTasks[i]\
						end\
						if i == #task.SubTasks then\
							nTask.SubTasks[i].Next = nil\
						end\
						if nTask.SubTasks[i].SubTasks then\
							nTask.SubTasks[i].SubTasks.parent = nTask.SubTasks\
						end\
					end\
				else\
					nTask[k] = copyTable(task[k],true)\
				end\
			end\
		end\
	end		-- for k,v in pairs(task) do ends\
	if not keepOldTaskParents and nTask.SubTasks then\
		-- Correct for the task parents of all subtasks\
		Karm.TaskObject.applyFuncHier(nTask,function(task, subTaskParent)\
								if task.SubTasks then\
									if subTaskParent then\
										task.SubTasks.parent = task.Parent.SubTasks\
									end\
									for i = 1,#task.SubTasks do\
										task.SubTasks[i].Parent = task\
									end\
								end\
								return true\
							end\
		)\
	end\
	Karm.TaskObject.MakeTaskObject(nTask)\
	return nTask\
end		-- function Karm.TaskObject.copy(task)ends\
\
function Karm.TaskObject.MakeTaskObject(task)\
	setmetatable(task,Karm.TaskObject)\
end\
\
-- Function to convert a task to a task list with incremental schedules i.e. 1st will be same as task passed (but a copy of it) and last task will have 1st schedule only\
-- The task ID however have additional _n where n is a serial number from 1 \
function Karm.TaskObject.incSchTasks(task)\
	local taskList = {}\
	taskList[1] = Karm.TaskObject.copy(task)\
	taskList[1].TaskID = taskList[1].TaskID..\"_1\"\
	while taskList[#taskList].Schedules do\
		-- Find the latest schedule in the task here\
		if string.upper(taskList[#taskList].Status) == \"DONE\" and taskList[#taskList].Schedules.Actual then\
			-- Actual Schedule is the latest so remove this one\
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])\
			-- Remove the actual schedule\
			taskList[#taskList].Schedules.Actual = nil\
			-- Change the task ID\
			taskList[#taskList].TaskID = task.TaskID..\"_\"..tostring(#taskList)\
		elseif taskList[#taskList].Schedules.Revs then\
			-- Actual is not the latest one but Revision is \
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])\
			-- Remove the latest Revision Schedule\
			taskList[#taskList].Schedules.Revs[taskList[#taskList].Schedules.Revs.count] = nil\
			taskList[#taskList].Schedules.Revs.count = taskList[#taskList].Schedules.Revs.count - 1\
			if taskList[#taskList].Schedules.Revs.count == 0 then\
				taskList[#taskList].Schedules.Revs = nil\
			end\
			-- Change the task ID\
			taskList[#taskList].TaskID = task.TaskID..\"_\"..tostring(#taskList)\
		elseif taskList[#taskList].Schedules.Commit then\
			-- Actual and Revisions don't exist but Commit does\
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])\
			-- Remove the Commit Schedule\
			taskList[#taskList].Schedules.Commit = nil\
			-- Change the task ID\
			taskList[#taskList].TaskID = task.TaskID..\"_\"..tostring(#taskList)\
		elseif taskList[#taskList].Schedules.Estimate then\
			-- The latest is Estimate\
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])\
			-- Remove the latest Estimate Schedule\
			taskList[#taskList].Schedules.Estimate[taskList[#taskList].Schedules.Estimate.count] = nil\
			taskList[#taskList].Schedules.Estimate.count = taskList[#taskList].Schedules.Estimate.count - 1\
			if taskList[#taskList].Schedules.Estimate.count == 0 then\
				taskList[#taskList].Schedules.Estimate = nil\
			end\
			-- Change the task ID\
			taskList[#taskList].TaskID = task.TaskID..\"_\"..tostring(#taskList)\
		elseif not taskList[#taskList].Schedules.Estimate and not taskList[#taskList].Schedules.Commit\
		  and not taskList[#taskList].Schedules.Revs then\
		  	-- Since there can be an Actual Schedule but task is not done so Schedules cannot be nil\
		  	break\
		end\
		if not taskList[#taskList].Schedules.Estimate and not taskList[#taskList].Schedules.Commit \
		  and not taskList[#taskList].Schedules.Revs and not taskList[#taskList].Schedules.Actual then\
			taskList[#taskList].Schedules = nil\
		end\
	end			-- while taskList[#taskList].Schedules do ends\
	taskList[#taskList] = nil\
	return taskList\
end		-- function Karm.TaskObject.incSchTasks(task) ends\
\
-- Function to return an Empty task that satisfies the minimum requirements\
function Karm.getEmptyTask(SporeFile)\
	local nTask = {}\
	nTask[0] = \"Task\"\
	nTask.SporeFile = SporeFile\
	nTask.Title = \"DUMMY\"\
	nTask.TaskID = \"DUMMY\"\
	nTask.Start = \"1900-01-01\"\
	nTask.Public = true\
	nTask.Who = {[0] = \"Who\", count = 1,[1] = \"DUMMY\"}\
	nTask.Status = \"Not Started\"\
	Karm.TaskObject.MakeTaskObject(nTask)\
	return nTask\
end\
\
-- Function to cycle the planning schedule type for a task\
-- This function depends on the task setting methodology chosen to be in the sequence of Estimate->Commit->Revs->Actual\
-- So conversions are:\
-- Nothing->Estimate\
-- Estimate->Commit\
-- Commit->Revs\
-- Revs->Actual\
-- Actual->Back to Estimate\
function Karm.TaskObject.togglePlanningType(task,type)\
	if not task.Planning then\
		task.Planning = {}\
	end\
	if type == \"NORMAL\" then\
		local dateList = Karm.TaskObject.getLatestScheduleDates(task)\
		if not dateList then\
			dateList = {}\
			dateList.index = 0\
			dateList.typeSchedule = \"Estimate\"\
		end\
				\
		if not task.Planning.Type then\
			if dateList.typeSchedule == \"Estimate\" then\
				task.Planning.Type = \"Estimate\"\
				task.Planning.index = dateList.index + 1\
			elseif dateList.typeSchedule == \"Commit\" then\
				task.Planning.Type = \"Revs\"\
				task.Planning.index = 1\
			elseif dateList.typeSchedule == \"Revs\" then\
				task.Planning.Type = \"Revs\"\
				task.Planning.index = dateList.index + 1\
			else\
				task.Planning.Type = \"Actual\"\
				task.Planning.index = 1		\
			end\
		elseif task.Planning.Type == \"Estimate\" then\
			task.Planning.Type = \"Commit\"\
			task.Planning.index = 1\
		elseif task.Planning.Type == \"Commit\" then\
			task.Planning.Type = \"Revs\"\
			if task.Schedules and task.Schedules.Revs then\
				task.Planning.index = #task.Schedules.Revs + 1\
			else\
				task.Planning.index = 1\
			end\
		elseif task.Planning.Type == \"Revs\" then\
			-- in \"NORMAL\" type the schedule does not go to \"Actual\"\
			task.Planning.Type = \"Estimate\"\
			if task.Schedules and task.Schedules.Estimate then\
				task.Planning.index = #task.Schedules.Estimate + 1\
			else\
				task.Planning.index = 1\
			end\
		end		-- if not task.Planning.Type then ends\
	else\
		task.Planning.Type = \"Actual\"\
		task.Planning.index = 1\
	end		-- if type == \"NORMAL\" then ends\
end\
\
\
-- Function to toggle a planning date in the given task. If the planning schedule table is not present it creates it with the schedule type Estimate\
-- returns 1 if added, 2 if removed, 3 if removed and no more planning schedule left\
function Karm.TaskObject.togglePlanningDate(task,xmlDate,type)\
	if not task.Planning then\
		Karm.TaskObject.togglePlanningType(task,type)\
		task.Planning.Period = {\
									[0]=\"Period\",\
									count=1,\
									[1]={\
											[0]=\"DP\",\
											Date = xmlDate\
										}\
								}\
		\
		return 1\
	end\
	if not task.Planning.Period then\
		task.Planning.Period = {\
									[0]=\"Period\",\
									count=1,\
									[1]={\
											[0]=\"DP\",\
											Date = xmlDate\
										}\
								}\
		\
		return 1\
	end\
	for i=1,task.Planning.Period.count do\
		if task.Planning.Period[i].Date == xmlDate then\
			-- Remove this date\
			for j=i+1,task.Planning.Period.count do\
				task.Planning.Period[j-1] = task.Planning.Period[j]\
			end\
			task.Planning.Period[task.Planning.Period.count] = nil\
			task.Planning.Period.count = task.Planning.Period.count - 1\
			if task.Planning.Period.count>0 then\
				return 2\
			else\
				task.Planning = nil\
				return 3\
			end\
		elseif task.Planning.Period[i].Date > xmlDate then\
			-- Insert Date here\
			task.Planning.Period.count = task.Planning.Period.count + 1\
			for j = task.Planning.Period.count,i+1,-1 do\
				task.Planning.Period[j] = task.Planning.Period[j-1]\
			end\
			task.Planning.Period[i] = {[0]=\"DP\",Date=xmlDate}\
			return 1\
		end\
	end\
	-- Date must be added in the end\
	task.Planning.Period.count = task.Planning.Period.count + 1\
	task.Planning.Period[task.Planning.Period.count] = {[0]=\"DP\",Date = xmlDate	}\
	return 1\
end\
\
function Karm.TaskObject.add2Spore(task,dataStruct)\
	if not task.SubTasks then\
		task.SubTasks = {parent = dataStruct, tasks = 0, [0]=\"SubTasks\"}\
	end\
	dataStruct.tasks = dataStruct.tasks + 1\
	dataStruct[dataStruct.tasks] = task \
	if dataStruct.tasks > 1 then\
		dataStruct[dataStruct.tasks - 1].Next = dataStruct[dataStruct.tasks]\
		dataStruct[dataStruct.tasks].Previous = dataStruct[dataStruct.tasks-1]\
	end\
end\
\
function Karm.TaskObject.getNewChildTaskID(parent)\
	local taskID\
	if not parent.SubTasks then\
		taskID = parent.TaskID..\"_1\"\
	else \
		local intVar1 = 0\
		for count = 1,#parent.SubTasks do\
	        local tempTaskID = parent.SubTasks[count].TaskID\
	        if tonumber(tempTaskID:sub(-(#tempTaskID - #parent.TaskID - 1),-1)) > intVar1 then\
	            intVar1 = tonumber(tempTaskID:sub(-(#tempTaskID - #parent.TaskID - 1),-1))\
	        end\
		end\
		intVar1 = intVar1 + 1\
		taskID = parent.TaskID..\"_\"..tostring(intVar1)\
	end\
	return taskID\
end\
\
-- Function to add a task to a parent as a subtask\
function Karm.TaskObject.add2Parent(task, parent, Spore)\
	if not (task and parent) then\
		error(\"nil parameter cannot be handled at add2Parent in DataHandler.lua.\",2)\
	end\
	if getmetatable(task) ~= Karm.TaskObject or getmetatable(parent) ~= Karm.TaskObject then\
		error(\"Need a valid task and parent task object to add the task to parent\", 2)\
	end\
	if not parent.SubTasks then\
		parent.SubTasks = {tasks = 0, [0]=\"SubTasks\"}\
		if not parent.Parent then\
			---- THIS CONDITION SHOULD NEVER OCCUR SINCE A ROOT TASK ADDED TO A SPORE ALWAYS HAS A SUBTASKS NODE TO LINK TO THE SPORE TABLE\
			---- SEE add2Spore above\
			if not Spore then\
				error(\"Spore cannot be nil in Karm.TaskObject.add2Parent call.\",2)\
			end\
			-- This is a Spore root node\
			parent.SubTasks.parent = Spore\
		else\
			parent.SubTasks.parent = parent.Parent.SubTasks\
		end \
	end\
	parent.SubTasks.tasks = parent.SubTasks.tasks + 1\
	parent.SubTasks[parent.SubTasks.tasks] = task\
	if parent.SubTasks.tasks > 1 then\
		parent.SubTasks[parent.SubTasks.tasks - 1].Next = parent.SubTasks[parent.SubTasks.tasks]\
		parent.SubTasks[parent.SubTasks.tasks].Previous = parent.SubTasks[parent.SubTasks.tasks-1]\
	else\
		parent.SubTasks[parent.SubTasks.tasks].Previous = nil\
	end\
	parent.SubTasks[parent.SubTasks.tasks].Next = nil\
	if task.SubTasks then \
		task.SubTasks.parent = parent.SubTasks\
	end\
end\
\
-- Function to get all work done dates for a task and color and type for each date\
-- This function is called by the taskTree UI element to display the Gantt chart\
-- if bubble is true it bubbles up the latest schedule dates of the entire task hierarchy to this task\
--\
-- The function returns a table in the following format\
-- typeSchedule - Type of schedule for this task\
-- index - index of schedule for this task\
-- Subtables starting from index 1 corresponding to each date\
	-- Each subtable has the following keys:\
	-- Date - XML format date \
	-- typeSchedule - Type of schedule the date comes from \"Estimate\", \"Commit\", \"Revision\", \"Actual\"\
	-- index - the index of the schedule\
	-- Bubbled - True/False - True if date is from a subtask \
	-- BackColor - Background Color (Red, Green, Blue) table for setting the background color in the Gantt Chart\
	-- ForeColor - Foreground Color (Red, Green, Blue) table for setting the test color in the Gantt Chart date\
	-- Text - Text to be written in the Gantt cell for the date\
function Karm.TaskObject.getWorkDates(task,bubble)\
	local updateDateTable = function(task,dateTable)\
		local dateList = Karm.TaskObject.getWorkDoneDates(task)\
		if dateList then\
			if not dateTable then\
				dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}\
			end\
			for i = 1,#dateList do\
				local found = false\
				local index = 0\
				for j = 1,#dateTable do\
					if dateTable[j].Date == dateList[i] then\
						found = true\
						break\
					end\
					if dateTable[j].Date > dateList[i] then\
						index = j\
						break\
					end\
				end\
				if not found then\
					-- Create a space at index\
					for j = #dateTable, index, -1 do\
						dateTable[j+1] = dateTable[j]\
					end\
					local newColor = {Red=Karm.GUI.ScheduleColor.Red - Karm.GUI.bubbleOffset.Red,Green=Karm.GUI.ScheduleColor.Green - Karm.GUI.bubbleOffset.Green,\
					Blue=Karm.GUI.ScheduleColor.Blue-Karm.GUI.bubbleOffset.Blue}\
					if newColor.Red < 0 then newColor.Red = 0 end\
					if newColor.Green < 0 then newColor.Green = 0 end\
					if newColor.Blue < 0 then newColor.Blue = 0 end\
					dateTable[index] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, \
					  Bubbled = true, BackColor = newColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = \"\"}\
				end\
			end		-- for i = 1,#dateList do ends\
		end		-- if dateList then ends\
		return dateTable\
	end\
	if bubble then\
		local dateTable = Karm.TaskObject.applyFuncHier(task,updateDateTable)\
		return dateTable\
	else \
		-- Just get the latest dates for this task\
		local dateList = Karm.TaskObject.getWorkDoneDates(task)\
		if dateList then\
			-- Convert the dateList to modified return table\
			local dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}\
			for i = 1,#dateList do\
				dateTable[i] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, \
				  Bubbled = nil, BackColor = Karm.GUI.ScheduleColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = \"\"}\
			end\
			return dateTable\
		else\
			return nil\
		end\
	end\
end\
\
-- Function to get all dates for a task and color and type for each date\
-- This function is called by the taskTree UI element to display the Gantt chart\
-- if bubble is true it bubbles up the latest schedule dates of the entire task hierarchy to this task\
-- if planning is true it returns the planning date list for this task\
--\
-- The function returns a table in the following format\
-- typeSchedule - Type of schedule for this task\
-- index - index of schedule for this task\
-- Subtables starting from index 1 corresponding to each date\
	-- Each subtable has the following keys:\
	-- Date - XML format date \
	-- typeSchedule - Type of schedule the date comes from \"Estimate\", \"Commit\", \"Revision\", \"Actual\"\
	-- index - the index of the schedule\
	-- Bubbled - True/False - True if date is from a subtask \
	-- BackColor - Background Color (Red, Green, Blue) table for setting the background color in the Gantt Chart\
	-- ForeColor - Foreground Color (Red, Green, Blue) table for setting the test color in the Gantt Chart date\
	-- Text - Text to be written in the Gantt cell for the date\
function Karm.TaskObject.getDates(task,bubble,planning)\
	local plan = planning\
	local updateDateTable = function(task,dateTable)\
		local dateList = Karm.TaskObject.getLatestScheduleDates(task,plan)\
		if dateList then\
			if not dateTable then\
				dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}\
			end\
			for i = 1,#dateList do\
				local found = false\
				local index = 0\
				for j = 1,#dateTable do\
					if dateTable[j].Date == dateList[i] then\
						found = true\
						break\
					end\
					if dateTable[j].Date > dateList[i] then\
						index = j - 1\
						break\
					end\
				end\
				if not found then\
					-- Create a space at index + 1\
					for j = #dateTable, index+1, -1 do\
						dateTable[j+1] = dateTable[j]\
					end\
					local newColor = {Red=Karm.GUI.ScheduleColor.Red - Karm.GUI.bubbleOffset.Red,Green=Karm.GUI.ScheduleColor.Green - Karm.GUI.bubbleOffset.Green,\
					Blue=Karm.GUI.ScheduleColor.Blue-Karm.GUI.bubbleOffset.Blue}\
					if newColor.Red < 0 then newColor.Red = 0 end\
					if newColor.Green < 0 then newColor.Green = 0 end\
					if newColor.Blue < 0 then newColor.Blue = 0 end\
					dateTable[index+1] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, \
					  Bubbled = true, BackColor = newColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = dateList.typeSchedule:sub(1,1)}\
				end\
			end		-- for i = 1,#dateList do ends\
		end		-- if dateList then ends\
		return dateTable\
	end\
	if bubble then\
		-- Main task schedule\
		local dateTable = updateDateTable(task)\
		if dateTable then\
			for i = 1,#dateTable do\
				dateTable[i].Bubbled = nil\
				dateTable[i].BackColor = Karm.GUI.ScheduleColor\
				dateTable[i].Text = \"\"\
			end\
		end\
		plan = nil\
		dateTable = Karm.TaskObject.applyFuncHier(task,updateDateTable,dateTable, true)\
		return dateTable\
	else \
		-- Just get the latest dates for this task\
		local dateList = Karm.TaskObject.getLatestScheduleDates(task,planning)\
		if dateList then\
			-- Convert the dateList to modified return table\
			local dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}\
			for i = 1,#dateList do\
				dateTable[i] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, \
				  Bubbled = nil, BackColor = Karm.GUI.ScheduleColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = \"\"}\
			end\
			return dateTable\
		else\
			return nil\
		end\
	end\
end\
\
-- function to update the taskID in the whole hierarchy\
function Karm.TaskObject.updateTaskID(task,taskID)\
	if not(task and taskID) then\
		error(\"Need a task and taskID for Karm.TaskObject.updateTaskID in DataHandler.lua\",2)\
	end\
	local prevTaskID = task.TaskID\
	Karm.TaskObject.applyFuncHier(task,function(task,taskIDs)\
							task.TaskID = task.TaskID:gsub(\"^\"..taskIDs.prevTaskID,taskIDs.newTaskID)\
							return taskIDs\
						end, {prevTaskID = prevTaskID, newTaskID = taskID}\
	)\
end\
\
-- Old Version\
--function Karm.TaskObject.updateTaskID(task,taskID)\
--	if not(task and taskID) then\
--		error(\"Need a task and taskID for Karm.TaskObject.updateTaskID in DataHandler.lua\",2)\
--	end\
--	local prevTaskID = task.TaskID\
--	task.TaskID = taskID\
--	if task.SubTasks then\
--		local currNode = task.SubTasks\
--		local hierCount = {}\
--		-- Traverse the task hierarchy here\
--		hierCount[currNode] = 0\
--		while hierCount[currNode] < #currNode or currNode.parent do\
--			if not(hierCount[currNode] < #currNode) then\
--				if currNode == task.SubTasks then\
--					-- Do not go above the passed task\
--					break\
--				end \
--				currNode = currNode.parent\
--			else\
--				-- Increment the counter\
--				hierCount[currNode] = hierCount[currNode] + 1\
--				currNode[hierCount[currNode]].TaskID = currNode[hierCount[currNode]].TaskID:gsub(\"^\"..prevTaskID,task.TaskID)\
--				if currNode[hierCount[currNode]].SubTasks then\
--					-- This task has children so go deeper in the hierarchy\
--					currNode = currNode[hierCount[currNode]].SubTasks\
--					hierCount[currNode] = 0\
--				end\
--			end\
--		end		-- while hierCount[hier] < #hier or hier.parent do ends here\
--	end		-- if task.SubTasks then ends\
--end\
\
-- Function to move the task before/after\
function Karm.TaskObject.bubbleTask(task,relative,beforeAfter,parent)\
	if task.Parent ~= relative.Parent then\
		error(\"The task and relative should be on the same level in the Karm.TaskObject.bubbleTask call in DataHandler.lua\",2)\
	end\
	if not (task.Parent or parent) then\
		error(\"parent argument should be specified for tasks/relative that do not have a parent defined in Karm.TaskObject.bubbleTask call in DataHandler.lua\",2)\
	end	\
	if task==relative then\
		return\
	end\
	local pTable, swapID\
	if not task.Parent then\
		-- These are root nodes in a spore\
		pTable = parent\
		swapID = false	-- since IDs for spore root nodes should not be swapped since they are roots and unique\
	else\
		pTable = relative.Parent.SubTasks\
		swapID = true\
	end\
	if beforeAfter:upper() == \"AFTER\" then\
		-- Next Sibling\
		-- Find the relative and task number\
		local posRel, posTask\
		for i = 1,pTable.tasks do\
			if pTable[i] == relative then\
				posRel = i\
			end\
			if pTable[i] == task then\
				posTask = i\
			end\
		end\
		if posRel < posTask then\
			-- Start the bubble up \
			for i = posTask,posRel+2,-1 do\
				if swapID then\
					-- Swap TaskID\
					local tim1 = pTable[i].TaskID\
					local ti = pTable[i-1].TaskID\
					Karm.TaskObject.updateTaskID(pTable[i],ti) \
					Karm.TaskObject.updateTaskID(pTable[i-1],tim1)\
				end \
				-- Swap task position\
				pTable[i],pTable[i-1] = pTable[i-1],pTable[i]\
				-- Update the Previous and Next pointers\
				pTable[i].Previous = pTable[i-1]\
				pTable[i-1].Next = pTable[i]\
				if i > 2 then\
					pTable[i-2].Next = pTable[i-1]\
					pTable[i-1].Previous = pTable[i-2]\
				else\
					pTable[i-1].Previous = nil\
				end\
				if i < pTable.tasks then\
					pTable[i].Next = pTable[i+1]\
					pTable[i+1].Previous = pTable[i]\
				else\
					pTable[i].Next = nil\
				end\
			end\
		else\
			-- Start the bubble down \
			for i = posTask,posRel-1 do\
				if swapID then\
					-- Swap TaskID\
					local tip1 = pTable[i].TaskID\
					local ti = pTable[i+1].TaskID\
					Karm.TaskObject.updateTaskID(pTable[i],ti) \
					Karm.TaskObject.updateTaskID(pTable[i+1],tip1)\
				end \
				-- Swap task position\
				pTable[i],pTable[i+1] = pTable[i+1],pTable[i]\
				-- Update the Previous and Next pointers\
				pTable[i+1].Previous = pTable[i]\
				pTable[i].Next = pTable[i+1]\
				if i > 1 then\
					pTable[i-1].Next = pTable[i]\
					pTable[i].Previous = pTable[i-1]\
				else\
					pTable[i].Previous = nil\
				end\
				if i+1 < pTable.tasks then\
					pTable[i+1].Next = pTable[i+2]\
					pTable[i+2].Previous = pTable[i+1]\
				else\
					pTable[i+1].Next = nil\
				end\
			end\
		end\
	else\
		-- Previous sibling\
		-- Find the relative and task number\
		local posRel, posTask\
		for i = 1,pTable.tasks do\
			if pTable[i] == relative then\
				posRel = i\
			end\
			if pTable[i] == task then\
				posTask = i\
			end\
		end\
		if posRel < posTask then\
			-- Start the bubble up \
			for i = posTask,posRel+1,-1 do\
				if swapID then\
					-- Swap TaskID\
					local tim1 = pTable[i].TaskID\
					local ti = pTable[i-1].TaskID\
					Karm.TaskObject.updateTaskID(pTable[i],ti) \
					Karm.TaskObject.updateTaskID(pTable[i-1],tim1)\
				end \
				-- Swap task position\
				pTable[i],pTable[i-1] = pTable[i-1],pTable[i]\
				-- Update the Previous and Next pointers\
				pTable[i].Previous = pTable[i-1]\
				pTable[i-1].Next = pTable[i]\
				if i > 2 then\
					pTable[i-2].Next = pTable[i-1]\
					pTable[i-1].Previous = pTable[i-2]\
				else\
					pTable[i-1].Previous = nil\
				end\
				if i < pTable.tasks then\
					pTable[i].Next = pTable[i+1]\
					pTable[i+1].Previous = pTable[i]\
				else\
					pTable[i].Next = nil\
				end\
			end\
		else\
			-- Start the bubble down \
			for i = posTask,posRel-2 do\
				if swapID then\
					-- Swap TaskID\
					local tip1 = pTable[i].TaskID\
					local ti = pTable[i+1].TaskID\
					Karm.TaskObject.updateTaskID(pTable[i],ti) \
					Karm.TaskObject.updateTaskID(pTable[i+1],tip1)\
				end \
				-- Swap task position\
				pTable[i],pTable[i+1] = pTable[i+1],pTable[i]\
				-- Update the Previous and Next pointers\
				pTable[i+1].Previous = pTable[i]\
				pTable[i].Next = pTable[i+1]\
				if i > 1 then\
					pTable[i-1].Next = pTable[i]\
					pTable[i].Previous = pTable[i-1]\
				else\
					pTable[i].Previous = nil\
				end\
				if i+1 < pTable.tasks then\
					pTable[i+1].Next = pTable[i+2]\
					pTable[i+2].Previous = pTable[i+1]\
				else\
					pTable[i+1].Next = nil\
				end\
			end\
		end\
	end\
\
end\
\
--function DeleteTaskFromSpore(task, Spore)\
--	if task.Parent then\
--		error(\"DeleteTaskFromSpore: Cannot delete task that is not a root task in Spore.\",2)\
--	end\
--	local taskList\
--	taskList = Spore\
--	for i = 1,#taskList do\
--		if taskList[i] == task then\
--			for j = i, #taskList-1 do\
--				taskList[j] = taskList[j+1]\
--			end\
--			taskList[#taskList] = nil\
--			taskList.tasks = taskList.tasks - 1\
--			break\
--		end\
--	end\
--end\
\
function Karm.TaskObject.DeleteFromDB(task)\
	local taskList\
	if not task.Parent then\
		taskList = task.SubTasks.parent		\
	else\
		taskList = task.Parent.SubTasks\
	end\
	for i = 1,#taskList do\
		if taskList[i] == task then\
			if i<#taskList then\
				for j = i, #taskList-1 do\
					taskList[j] = taskList[j+1]\
					if j>1 then\
						taskList[j].Previous = taskList[j-1]\
						taskList[j-1].Next = taskList[j]\
					else\
						taskList[j].Previous = nil\
					end\
				end\
			else\
				if #taskList > 1 then\
					taskList[i-1].Next = nil\
				end\
			end\
			taskList[#taskList] = nil\
			taskList.tasks = taskList.tasks - 1\
			break\
		end\
	end\
end\
\
function Karm.sporeTitle(path)\
	-- Find the name of the file\
	local strVar\
	local intVar1 = -1\
	for intVar = #path,1,-1 do\
		if string.sub(path, intVar, intVar) == \".\" then\
	    	intVar1 = intVar\
		end\
		if string.sub(path, intVar, intVar) == \"\\\\\" or string.sub(path, intVar, intVar) == \"/\" then\
	    	strVar = string.sub(path, intVar + 1, intVar1-1)\
	    	break\
		end\
	end\
	if not strVar then\
		strVar = path\
	end\
	return strVar\
end\
\
function Karm.TaskObject.IsSpore(task)\
	if task.TaskID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then\
		return true\
	else\
		return false\
	end\
end\
\
-- Function to convert XML data from a single spore to internal data structure\
-- Task structure\
-- Task.\
--	Planning.\
--	[0] = Task\
-- 	SporeFile\
--	Title\
--	Modified\
--	DBDATA.\
--	TaskID\
--	Start\
--	Fin\
--	Private\
--	Who.\
--	Access.\
--	Assignee.\
--	Status\
--	Parent. = Pointer to the Task to which this is a sub task (Nil for root tasks in a Spore)\
--  Next. = Pointer to the next task under the same Parent (Nil if this is the last task)\
--  Previous. = Pointer to the previous task under the same Parent (Nil if this is the first task)\
--	Priority\
--	Due\
--	Comments\
--	Cat\
--	SubCat\
--	Tags.\
--	Schedules.\
--		[0] = \"Schedules\"\
--		Estimate.\
--			[0] = \"Estimate\"\
--			count\
--			[i] = \
--		Commit.\
--			[0] = \"Commit\"\
--		Revs\
--		Actual\
--	SubTasks.\
--		[0] = \"SubTasks\"\
--		parent  = pointer to the array containing the list of tasks having the task whose SubTask Node this is (Points to Spore table for root tasks of a Spore)\
--		tasks = count of number of subtasks\
--		[i] = Task table like this one repeated for sub tasks\
\
function Karm.XML2Data(SporeXML, SporeFile)\
	-- tasks counts the number of tasks at the current level\
	-- index 0 contains the name of this level to make it compatible with LuaXml\
	local dataStruct = {Title = Karm.sporeTitle(SporeFile), SporeFile = SporeFile, tasks = 0, TaskID = Karm.Globals.ROOTKEY..SporeFile, [0] = \"Task_Spore\"}	-- to create the data structure\
	if SporeXML[0]~=\"Task_Spore\" then\
		return nil\
	end\
	local currNode = SporeXML		-- currNode contains the current XML node being processed\
	local hierInfo = {}\
	hierInfo[currNode] = {count = 1}		-- hierInfo contains associated information with the currNode i.e. its Parent and count of the node being processed\
	while(currNode[hierInfo[currNode].count] or hierInfo[currNode].parent) do\
		if not(currNode[hierInfo[currNode].count]) then\
			currNode = hierInfo[currNode].parent\
			dataStruct = dataStruct.parent\
		else\
			if currNode[hierInfo[currNode].count][0] == \"Task\" then\
				local task = currNode[hierInfo[currNode].count]\
				hierInfo[currNode].count = hierInfo[currNode].count + 1\
				local necessary = 0\
				dataStruct.tasks = dataStruct.tasks + 1\
				dataStruct[dataStruct.tasks] = {[0] = \"Task\"}\
				\
				dataStruct[dataStruct.tasks].SporeFile = SporeFile\
				-- Set the Previous and next pointers\
				if dataStruct.tasks > 1 then\
					dataStruct[dataStruct.tasks].Previous = dataStruct[dataStruct.tasks - 1]\
				end\
				dataStruct[dataStruct.tasks].Next = dataStruct[dataStruct.tasks + 1]\
				-- Each task has a Parent Attribute which points to a parent Task containing this task. For root tasks in the spore this is nil\
				dataStruct[dataStruct.tasks].Parent = hierInfo[currNode].parentTask\
				-- Extract all task information here\
				local count = 1\
				while(task[count]) do\
					if task[count][0] == \"Title\" then\
						dataStruct[dataStruct.tasks].Title = task[count][1]\
						necessary = necessary + 1\
					elseif task[count][0] == \"Modified\" then\
						if task[count][1] == \"YES\" then\
							dataStruct[dataStruct.tasks].Modified = true\
						else\
							dataStruct[dataStruct.tasks].Modified = false\
						end\
						necessary = necessary + 1\
					elseif task[count][0] == \"DB-Data\" then\
						dataStruct[dataStruct.tasks].DBDATA = {[0]=\"DB-Data\",DBID = task[count][1][1], Updated = task[count][2][1]}\
					elseif task[count][0] == \"TaskID\" then\
						dataStruct[dataStruct.tasks].TaskID = task[count][1]\
						necessary = necessary + 1\
					elseif task[count][0] == \"Start\" then\
						dataStruct[dataStruct.tasks].Start = task[count][1]\
					elseif task[count][0] == \"Fin\" then\
						dataStruct[dataStruct.tasks].Fin = task[count][1]\
					elseif task[count][0] == \"Private\" then\
						if task[count][1] == \"Private\" then\
							dataStruct[dataStruct.tasks].Private = true\
						else\
							dataStruct[dataStruct.tasks].Private = false\
						end\
						necessary = necessary + 1\
					elseif task[count][0] == \"People\" then\
						for j = 1,#task[count] do\
							if task[count][j][0] == \"Who\" then\
								local WhoTable = {[0]=\"Who\", count = #task[count][j]}\
								-- Loop through all the items in the Who element\
								for i = 1,#task[count][j] do\
									WhoTable[i] = {ID = task[count][j][i][1][1], Status = task[count][j][i][2][1]}\
								end\
								necessary = necessary + 1\
								dataStruct[dataStruct.tasks].Who = WhoTable\
							elseif task[count][j][0] == \"Locked\" then\
								local locked = {[0]=\"Access\", count = #task[count][j]}\
								-- Loop through all the items in the Locked element Access List\
								for i = 1,#task[count][j] do\
									locked[i] = {ID = task[count][j][i][1][1], Status = task[count][j][i][2][1]}\
								end\
								dataStruct[dataStruct.tasks].Access = locked\
							elseif task[count][j][0] == \"Assignee\" then\
								local assignee = {[0]=\"Assignee\", count = #task[count][j]}\
								-- Loop through all the items in the Assignee element\
								for i = 1,#task[count][j] do\
									assignee[i] = {ID = task[count][j][i][1]}\
								end				\
								dataStruct[dataStruct.tasks].Assignee = assignee					\
							end		-- if task[count][j][0] == \"Who\" then ends here				\
						end		-- for j = 1,#task[count] do ends here				\
					elseif task[count][0] == \"Status\" then\
						dataStruct[dataStruct.tasks].Status = task[count][1]\
						necessary = necessary + 1\
					elseif task[count][0] == \"Priority\" then\
						dataStruct[dataStruct.tasks].Priority = task[count][1]\
					elseif task[count][0] == \"Due\" then\
						dataStruct[dataStruct.tasks].Due = task[count][1]\
					elseif task[count][0] == \"Comments\" then\
						dataStruct[dataStruct.tasks].Comments = task[count][1]\
					elseif task[count][0] == \"Category\" then\
						dataStruct[dataStruct.tasks].Cat = task[count][1]\
					elseif task[count][0] == \"Sub-Category\" then\
						dataStruct[dataStruct.tasks].SubCat = task[count][1]\
					elseif task[count][0] == \"Tags\" then\
						local tagTable = {[0]=\"Tags\", count = #task[count]}\
						-- Loop through all the items in the Tags element\
						for i = 1,#task[count] do\
							tagTable[i] = task[count][i][1]\
						end\
						dataStruct[dataStruct.tasks].Tags = tagTable\
					elseif task[count][0] == \"Schedules\" then\
						local schedule = {[0]=\"Schedules\"}\
						for i = 1,#task[count] do\
							if task[count][i][0] == \"Estimate\" then\
								local estimate = {[0]=\"Estimate\", count = #task[count][i]}\
								-- Loop through all the estimates\
								for j = 1,#task[count][i] do\
									estimate[j] = {[0]=\"Estimate\"}\
									-- Loop through the children of Estimates element\
									for n = 1,#task[count][i][j] do\
										if task[count][i][j][n][0] == \"Hours\" then\
											estimate[j].Hours = task[count][i][j][n][1]\
										elseif task[count][i][j][n][0] == \"Comment\" then\
											estimate[j].Comment = task[count][i][j][n][1]\
										elseif task[count][i][j][0] == \"Updated\" then\
											estimate[j].Updated = task[count][i][j][n][1]\
										elseif task[count][i][j][n][0] == \"Period\" then\
											local period = {[0] = \"Period\", count = #task[count][i][j][n]}\
											-- Loop through all the day plans\
											for k = 1,#task[count][i][j][n] do\
												period[k] = {[0] = \"DP\", Date = task[count][i][j][n][k][1][1]}\
												if task[count][i][j][n][k][2] then\
													if task[count][i][j][n][k][2] == \"Hours\" then\
														period[k].Hours = task[count][i][j][n][k][2][1]\
													else\
														-- Collect all the time plans\
														period[k].TP = {[0]=\"Time Plan\", count = #task[count][i][j][n][k]-1}\
														for m = 2,#task[count][i][j][n][k] do\
															-- Add this time plan to the kth day plan\
															period[k].TP[m-1] = {STA = task[count][i][j][n][k][m][1][1], STP = task[count][i][j][n][k][m][2][1]}\
														end\
													end\
												end		-- if task[count][i][n][k][2] then ends\
											end		-- for k = 1,#task[count][i][j] do ends\
											estimate[j].Period = period\
										end		-- if task[count][i][j][0] == \"Hours\" then ends\
									end		-- for n = 1,#task[count][i][j] do ends\
								end		-- for j = 1,#task[count][i] do ends\
								schedule.Estimate = estimate\
							elseif task[count][i][0] == \"Commit\" then\
								local commit = {[0]=\"Commit\"}\
								commit.Comment = task[count][i][1][1][1]\
								commit.Updated = task[count][i][1][2][1]\
								local period = {[0] = \"Period\", count = #task[count][i][1][3]}\
								-- Loop through all the day plans\
								for k = 1,#task[count][i][1][3] do\
									period[k] = {[0] = \"DP\", Date = task[count][i][1][3][k][1][1]}\
									if task[count][i][1][3][k][2] then\
										if task[count][i][1][3][k][2] == \"Hours\" then\
											period[k].Hours = task[count][i][1][3][k][2][1]\
										else\
											-- Collect all the time plans\
											period[k].TP = {[0]=\"Time Plan\", count = #task[count][i][1][3][k]-1}\
											for m = 2,#task[count][i][1][3][k] do\
												-- Add this time plan to the kth day plan\
												period[k].TP[m-1] = {STA = task[count][i][1][3][k][m][1][1], STP = task[count][i][1][3][k][m][2][1]}\
											end\
										end\
									end		-- if task[count][i][n][k][2] then ends\
								end		-- for k = 1,#task[count][i][j] do ends\
								commit.Period = period\
								schedule.Commit = {commit,[0]=\"Commit\", count = 1}\
							elseif task[count][i][0] == \"Revs\" then\
								local revs = {[0]=\"Revs\", count = #task[count][i]}\
								-- Loop through all the Revisions\
								for j = 1,#task[count][i] do\
									revs[j] = {[0]=\"Revs\"}\
									-- Loop through the children of Revision element\
									for n = 1,#task[count][i][j] do\
										if task[count][i][j][n][0] == \"Comment\" then\
											revs[j].Comment = task[count][i][j][n][1]\
										elseif task[count][i][j][0] == \"Updated\" then\
											revs[j].Updated = task[count][i][j][n][1]\
										elseif task[count][i][j][n][0] == \"Period\" then\
											local period = {[0] = \"Period\", count = #task[count][i][j][n]}\
											-- Loop through all the day plans\
											for k = 1,#task[count][i][j][n] do\
												period[k] = {[0] = \"DP\", Date = task[count][i][j][n][k][1][1]}\
												if task[count][i][j][n][k][2] then\
													if task[count][i][j][n][k][2] == \"Hours\" then\
														period[k].Hours = task[count][i][j][n][k][2][1]\
													else\
														-- Collect all the time plans\
														period[k].TP = {[0]=\"Time Plan\", count = #task[count][i][j][n][k]-1}\
														for m = 2,#task[count][i][j][n][k] do\
															-- Add this time plan to the kth day plan\
															period[k].TP[m-1] = {STA = task[count][i][j][n][k][m][1][1], STP = task[count][i][j][n][k][m][2][1]}\
														end\
													end\
												end		-- if task[count][i][n][k][2] then ends\
											end		-- for k = 1,#task[count][i][j] do ends\
											revs[j].Period = period\
										end		-- if task[count][i][j][0] == \"Hours\" then ends\
									end		-- for n = 1,#task[count][i][j] do ends\
								end		-- for j = 1,#task[count][i] do ends\
								schedule.Revs = revs\
							elseif task[count][i][0] == \"Actual\" then\
								local actual = {[0]= \"Actual\", count = 1}\
								local period = {[0] = \"Period\", count = #task[count][i]-1} \
								-- Loop through all the work done elements\
								for j = 2,period.count+1 do\
									period[j] = {[0]=\"WD\", Date = task[count][i][j][1][1]}\
									for k = 2,#task[count][i][j] do\
										if task[count][i][j][k][0] == \"Hours\" then\
											period[j].Hours = task[count][i][j][k][1]\
										elseif task[count][i][j][k][0] == \"Comment\" then\
											period[j].Comment = task[count][i][j][k][1]\
										end\
									end\
								end\
								actual[1] = {Period = period,[0]=\"Actual\", Updated = task[count][i][1][1]}\
								schedule.Actual = actual\
							end							\
						end\
						dataStruct[dataStruct.tasks].Schedules = schedule\
					elseif task[count][0] == \"SubTasks\" then\
						hierInfo[task[count]] = {count = 1, parent = currNode,parentTask = dataStruct[dataStruct.tasks]}\
						currNode = task[count]\
						dataStruct[dataStruct.tasks].SubTasks = {parent = dataStruct, tasks = 0, [0]=\"SubTasks\"}\
						dataStruct = dataStruct[dataStruct.tasks].SubTasks\
					end\
					count = count + 1\
				end		-- while(task[count]) do ends\
				if necessary < 6 then\
					-- this is not valid task\
					dataStruct[dataStruct.tasks] = nil\
					dataStruct.tasks = dataStruct.tasks - 1\
				end\
			else\
				if currNode[hierInfo[currNode].parent] then\
					currNode = hierInfo[currNode].parent\
					dataStruct = dataStruct.parent\
				end		-- if currNode[hierInfo[level].parent ends here\
			end		-- if currNode[hierInfo[level].count][0] == \"Task\"  ends here\
		end		-- if not(currNode[hierInfo[currNode].count]) then ends\
	end		-- while(currNode[hierInfo[level].count]) ends here\
	while dataStruct.parent do\
		dataStruct = dataStruct.parent\
	end\
	\
	-- Convert all tasks to proper task Objects\
	local list1 = Karm.FilterObject.applyFilterHier(nil,dataStruct)\
	if #list1 > 0 then\
		for i = 1,#list1 do\
			Karm.TaskObject.MakeTaskObject(list1[i])\
		end\
	end        	\
	\
	-- Create a SubTasks node for each root node to get link to spore data table\
	for i = 1,#dataStruct do\
		if not dataStruct[i].SubTasks then\
			dataStruct[i].SubTasks = {parent = dataStruct, tasks = 0, [0]=\"SubTasks\"}\
		end\
	end\
	return dataStruct\
end		-- function Karm.XML2Data(SporeXML) ends here\
"
-----------------------------------------------------------------------------
-- Application: Karm
-- Purpose:     Karm application main file forms the frontend and handles the GUI
-- Author:      Milind Gupta
-- Created:     1/13/2012
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
-- For windows distribution
--package.cpath = ";./?.dll;"

-- For linux distribution
package.cpath = ";./?.so;/usr/lib/?.so;/usr/local/lib/?.so;"

require("wx")

-- DO ALL CONFIGURATION
Karm = {}
-- Table to store the core functions when they are being overwritten
Karm.Core = {}
--[[
do
	local KarmMeta = {__metatable = "Hidden, Do not change!"}
	KarmMeta.__newindex = function(tab,key,val)
		if Karm.key and not Karm.Core.key then
			Karm.Core.key = Karm.key
		end
		rawset(Karm,key,val)
	end
	setmetatable(Karm,KarmMeta)
end]]
-- Table to store all the Spores data 
Karm.SporeData = {}


-- Creating GUI the main table containing all the GUI objects and data
Karm.GUI = {
	-- Node Colors
	nodeForeColor = {Red=0,Green=0,Blue=0},
	nodeBackColor = {Red=255,Green=255,Blue=255},
	-- Gantt Colors
	noScheduleColor = {Red=210,Green=210,Blue=210},
	ScheduleColor = {Red=0,Green=180,Blue=215},
	emptyDayColor = {Red=255,Green=255,Blue=255},
	sunDayOffset = {Red = 30, Green=30, Blue = 30},
	bubbleOffset = {Red = 20, Green=20, Blue = 20},
	defaultColor = {Red=0,Green=0,Blue=0},
	highLightColor = {Red=120,Green=120,Blue=120},
	
	
	-- Task status colors
	-- Main Menu
	MainMenu = {
					-- 1st Menu
					{	
						Text = "&File", Menu = {
											{Text = "Change &ID\tCtrl-I", HelpText = "Change the User ID", Code = [[
local user = wx.wxGetTextFromUser("Enter the user ID (Blank to cancel)", "User ID", "")
if user ~= "" then
	Karm.Globals.User = user
	Karm.GUI.frame:SetTitle("Karm ("..Karm.Globals.User..")")
end											
											]]},
												{Text = "E&xit\tCtrl-x", HelpText = "Quit the program", Code = "Karm.GUI.frame:Close(true)"}
										}
					},
					-- 2nd Menu
					{	
						Text = "&Help", Menu = {
												{Text = "&About\tCtrl-A", HelpText = "About Karm", Code = "wx.wxMessageBox('Karm is the Task and Project management application for everybody.\\n Version: '..Karm.Globals.KARM_VERSION, 'About Karm',wx.wxOK + wx.wxICON_INFORMATION,Karm.GUI.frame)"}
										}
					}
	}
}

Karm.GUI.initFrameW, Karm.GUI.initFrameH = wx.wxDisplaySize()
Karm.GUI.initFrameW = 0.75*Karm.GUI.initFrameW
Karm.GUI.initFrameH = 0.75*Karm.GUI.initFrameH
Karm.GUI.initFrameW = Karm.GUI.initFrameW - Karm.GUI.initFrameW%1
Karm.GUI.initFrameH = Karm.GUI.initFrameH - Karm.GUI.initFrameH%1

Karm.Core.GUI = {}
setmetatable(Karm.GUI,{__index = _G})
--[[
do
	local KarmMeta = {__metatable = "Hidden, Do not change!"}
	KarmMeta.__newindex = function(tab,key,val)
		if Karm.GUI.key and not Karm.Core.GUI.key then
			Karm.Core.GUI.key = Karm.GUI.key
		end
		rawset(Karm.GUI,key,val)
	end
	KarmMeta.__index = _G
	setmetatable(Karm.GUI,KarmMeta)
end
]]

-- Global Declarations
Karm.Globals = {
	ROOTKEY = "T0",
	KARM_VERSION = "1.12.09.04",
	PriorityList = {'1','2','3','4','5','6','7','8','9'},
	StatusList = {'Not Started','On Track','Behind','Done','Obsolete'},
	StatusNodeColor = {
				{	ForeColor = {Red=100,Green=100,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=0,Green=0,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=230,Green=0,Blue=0},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=0,Green=0,Blue=230},
					BackColor = {Red=255,Green=255,Blue=255}
				},
				{	ForeColor = {Red=200,Green=200,Blue=200},
					BackColor = {Red=255,Green=255,Blue=255}
				}
	},
	NoDateStr = "__NO_DATE__",
	NoTagStr = "__NO_TAG__",
	NoAccessIDStr = "__NO_ACCESS__",
	NoCatStr = "__NO_CAT__",
	NoSubCatStr = "__NO_SUBCAT__",
	NoPriStr = "__NO_PRI__",
	__DEBUG = true,		-- For debug mode
	PlanningMode = false,	-- Flag to indicate Schedule Planning mode is on.
	unsavedSpores = {},	-- To store list of unsaved Spores
	safeenv = {},
	UserIDPattern = "%'([%w%.%_%,]+)%'"
}

-- Generate a unique new wxWindowID
do
	local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
	function Karm.NewID()
	    ID_IDCOUNTER = ID_IDCOUNTER + 1
	    return ID_IDCOUNTER
	end
end

-- FINISH CONFIGURATION

-- INCLUDE ALL CODE

-- Include the XML handling module
requireLuaString('LuaXml')

-- Karm files
requireLuaString('Filter')
requireLuaString('DataHandler')
Karm.GUI.FilterForm = requireLuaString('FilterForm')		-- Containing all Filter Form GUI code
Karm.GUI.TaskForm = requireLuaString('TaskForm')		-- Containing all Task Form GUI code

-- FINISH CODE INCLUSION

do
	local IDMap = {}	-- Map from wxID to object (used to handle events)
	-- Metatable to define a node object's behaviour
	local nodeMeta = {__metatable = "Hidden, Do not change!"}
	local taskTreeINT = {__metatable = "Hidden, Do not change!"} 
	
	-- Function References
	local onScrollTree, onScrollGantt, labelClick, cellClick, horSashAdjust, widgetResize, refreshGantt, dispTask, dispGantt
	local cellClickCallBack, ganttCellClick, ganttLabelClick, ganttCellDblClick, onRowResizeGantt, onRowResizeTree

	-- Function to return the iterator function to iterate over all taskTree Nodes 
	-- This the function to be used in a Generic for
	function taskTreeINT.tpairs(taskTree)
		return taskTreeINT.nextNode, taskTree, nil
	end
	
	-- Iterator for all nodes will give the effect of iterating over all the tasks in the task tree sequentially as if the whole tree is expanded
	function taskTreeINT.nextNode(taskTree,index)
		-- index is the index of the node whose next node this function returns
		local i = index
		if not i then
			if not taskTreeINT[taskTree].Roots[1] then
				return nil,nil
			else
				return nodeMeta[taskTreeINT[taskTree].Roots[1]].Key, taskTreeINT[taskTree].Roots[1]
			end
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if this node has children
		if nodeMeta[oTree.Nodes[i]].FirstChild then
			return nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key, nodeMeta[oTree.Nodes[i]].FirstChild
		end
		-- No children so only way is next sibling or parents
		while oTree.Nodes[i] do
			if nodeMeta[oTree.Nodes[i]].Next then
				return nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key, nodeMeta[oTree.Nodes[i]].Next
			else
				-- No next siblings so go up a level and continue
				if nodeMeta[oTree.Nodes[i]].Parent then
					i = nodeMeta[nodeMeta[oTree.Nodes[i]].Parent].Key
				else
					i = nil
				end
			end
		end		-- while oTree.Nodes[i] do ends
	end
	
	-- Function to return the iterator function to iterate over only visible taskTree Nodes
	function taskTreeINT.tvpairs(taskTree)
		-- Note if taskTreeINT.update = false then the results of this iterator may not be in sync with what is seen on the GUI
		return taskTreeINT.nextVisibleNode, taskTree, nil
	end
	
	-- This iterator function totally relies on the presence of Row and Expanded Attributes
	-- From the given index it goes down only if the Expanded attribute is true and only gives a visible node if its Row attribute is present
	function taskTreeINT.nextVisibleNode(taskTree, index)
		-- index is the index of the node whose next node this function returns
		local i = index
		if not i then
			if not taskTreeINT[taskTree].Roots[1] then
				return nil,nil
			else
				return nodeMeta[taskTreeINT[taskTree].Roots[1]].Key, taskTreeINT[taskTree].Roots[1]
			end
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if this node is has children and is expanded
		if nodeMeta[oTree.Nodes[i]].FirstChild and nodeMeta[oTree.Nodes[i]].Expanded and nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Row then
			return nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key, nodeMeta[oTree.Nodes[i]].FirstChild
		elseif nodeMeta[oTree.Nodes[i]].FirstChild and nodeMeta[oTree.Nodes[i]].Expanded then
			return taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nodeMeta[oTree.Nodes[i]].FirstChild].Key)
		end
		-- No children visible so only way is next sibling or parents
		while oTree.Nodes[i] do
			if nodeMeta[oTree.Nodes[i]].Next and nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Row then
				return nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key, nodeMeta[oTree.Nodes[i]].Next
			elseif nodeMeta[oTree.Nodes[i]].Next then
				return taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nodeMeta[oTree.Nodes[i]].Next].Key)
			else
				-- No next siblings so go up a level and continue
				if nodeMeta[oTree.Nodes[i]].Parent then
					i = nodeMeta[nodeMeta[oTree.Nodes[i]].Parent].Key
				else
					i = nil
				end
			end
		end		-- while oTree.Nodes[i] do ends					
	end
	
	function taskTreeINT.associateEventFunc(taskTree,funcTable)
		taskTreeINT[taskTree].cellClickCallBack = funcTable.cellClickCallBack or taskTreeINT[taskTree].cellClickCallBack
		taskTreeINT[taskTree].ganttCellClickCallBack = funcTable.ganttCellClickCallBack or taskTreeINT[taskTree].ganttCellClickCallBack
		taskTreeINT[taskTree].rowLabelClickCallBack = funcTable.rowLabelClickCallBack or taskTreeINT[taskTree].rowLabelClickCallBack
		taskTreeINT[taskTree].ganttRowLabelClickCallBack = funcTable.ganttRowLabelClickCallBack or taskTreeINT[taskTree].ganttRowLabelClickCallBack
		taskTreeINT[taskTree].ganttCellDblClickCallBack = funcTable.ganttCellDblClickCallBack or taskTreeINT[taskTree].ganttCellDblClickCallBack
	end

	function taskTreeINT.dateRangeChange(o,startDate,finDate)
		-- Clear the GanttGrid
		taskTreeINT[o].ganttGrid:DeleteRows(0,o.ganttGrid:GetNumberRows())
		taskTreeINT[o].ganttGrid:DeleteCols(0,o.ganttGrid:GetNumberCols())
		local currDate = startDate
		local count = 0
		local corner = taskTreeINT[o].ganttGrid:GetGridCornerLabelWindow()
		-- Add the Month and year in the corner
		local sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
		local textLabel = wx.wxStaticText(corner, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
		textLabel:SetLabel(startDate:Format("%b %Y"))
		--textLabel:SetBackgroundColour(wx.wxColour(0,0,0))
		sizer:Add(textLabel, 1, wx.wxLEFT+wx.wxRIGHT+wx.wxALIGN_CENTRE_VERTICAL, 3)
		--corner:SetBackgroundColour(wx.wxColour(0,0,0))	
		corner:SetSizer(sizer)
		corner:Layout()	
		while not currDate:IsLaterThan(finDate) do
			taskTreeINT[o].ganttGrid:InsertCols(count)
			-- set the column labels
			taskTreeINT[o].ganttGrid:SetColLabelValue(count,string.sub(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y")),-2,-1)..
			    string.sub(Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))),1,1))
			taskTreeINT[o].ganttGrid:AutoSizeColumn(count)
			--taskTreeINT[o].ganttGrid:SetColLabelValue(count,string.sub(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y")),-5,-1))
			currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
			count = count + 1
		end
		taskTreeINT[o].startDate = startDate:Subtract(wx.wxDateSpan(0,0,0,count))
		taskTreeINT[o].finDate = finDate		
		refreshGantt(o)
	end
	
	function taskTreeINT.layout(taskTree)
		local oTree = taskTreeINT[taskTree]
		oTree.treeGrid:AutoSizeColumn(0)
	    oTree.treeGrid:SetColSize(1,oTree.horSplitWin:GetSashPosition()-oTree.treeGrid:GetColSize(0)-oTree.treeGrid:GetRowLabelSize(0))	
	end
	
	function taskTreeINT.disablePlanningMode(taskTree)
		local oTree = taskTreeINT[taskTree]
		oTree.Planning = nil
		if oTree.taskList then
			-- Update all the tasks in the planning mode in the UI to remove the planning schedule
			for i = 1,#oTree.taskList do
				if oTree.Nodes[oTree.taskList[i].TaskID].Row then
					dispGantt(taskTree,oTree.Nodes[oTree.taskList[i].TaskID].Row,false,oTree.Nodes[oTree.taskList[i].TaskID])
				end
			end 
			oTree.taskList = nil
		end
	end
	
	-- Function to enable the planning mode
	-- Type = "NORMAL" - Planning for normal schedules
	-- Type = "WORKDONE" - Planning for the actual work done schedule
	function taskTreeINT.enablePlanningMode(taskTree, taskList, type)
		local oTree = taskTreeINT[taskTree]
		taskList = taskList or {}
		type = type or "NORMAL"
		if type ~= "NORMAL" and type ~= "WORKDONE" then
			error("enablePlanningMode: Planning type should either be 'NORMAL' or 'WORKDONE'.",2)
		end
		oTree.Planning = type
		if not oTree.taskList then
			oTree.taskList = {}
			-- Check if there are tasks with Planning
			for i,v in taskTreeINT.tpairs(taskTree) do
				if v.Task and v.Task.Planning then
					oTree.taskList[#oTree.taskList + 1] = v.Task
				end
			end		-- Looping through all the nodes ends
		end
		-- Refresh the existing tasks in the taskList
		for j = 1,#oTree.taskList do
			if oTree.Nodes[oTree.taskList[j].TaskID]:MakeVisible() then
				dispGantt(taskTree,oTree.Nodes[oTree.taskList[j].TaskID].Row,false,oTree.Nodes[oTree.taskList[j].TaskID])
			end
		end
		for i = 1,#taskList do
			-- Check whether the task already exist in the taskList
			local found = false
			for j = 1,#oTree.taskList do
				if oTree.taskList[j] == taskList[i] then
					found = true
					break
				end
			end
			if not found then
				oTree.taskList[#oTree.taskList + 1] = taskList[i] 
				local dateList
				if type == "NORMAL" then
					-- Copy over the latest schedule to the planning period
					dateList = Karm.TaskObject.getLatestScheduleDates(taskList[i])
				else
					-- Copy over the work done dates to the planning period
					dateList = Karm.TaskObject.getWorkDoneDates(taskList[i])
				end		-- if type == "NORMAL" then ends
				if dateList then
					Karm.TaskObject.togglePlanningType(taskList[i],oTree.Planning)
					taskList[i].Planning.Period = {[0]="Period",count=0}
					for j=1,#dateList do
						taskList[i].Planning.Period[j] = {[0]="DP",Date=dateList[j]}
						taskList[i].Planning.Period.count = taskList[i].Planning.Period.count + 1
					end
				end
			end		-- if not found then ends
			if oTree.Nodes[taskList[i].TaskID]:MakeVisible() then
				dispGantt(taskTree,oTree.Nodes[taskList[i].TaskID].Row,false,oTree.Nodes[taskList[i].TaskID])
			end
		end		-- for i = 1,#taskList do ends
	end		-- local function enablePlanningMode(taskTree, taskList, type)ends
	
	function taskTreeINT.getPlanningTasks(taskTree)
		local oTree = taskTreeINT[taskTree]
		if not oTree.Planning then
			return nil
		else
			return oTree.taskList
		end
	end
	
	function taskTreeINT.getSelectedTask(taskTree)
		local oTree = taskTreeINT[taskTree]
		return oTree.Selected
	end
	
	function Karm.GUI.newTreeGantt(parent,noTaskTree)
		local taskTree = {}	-- Main object
		-- Main table to store the task tree that is on display
		taskTreeINT[taskTree] = {Nodes = {}, Roots = {}, update = true, nodeCount = 0, actionQ = {}, Planning = nil, taskList = nil, Selected = {},ShowActual = nil}
		-- A task in Nodes or Roots will have the following attributes:
		-- Expanded = if has children then true means it is expanded in the GUI
		-- MakeVisible = Function to make sure the task is visible
		-- Task = Contains the task data structure to the task
		-- Children = Contains the number of children on the tree for this node
		-- FirstChild = Contains the first child node
		-- LastChild = Contains the last child node
		-- Selected = Whether this node is selected. Allows multiple selections
		-- Title = Same as the task title unless there is no associated task
		-- Key = Same as TaskID unless no associated task
		-- ForeColor = Text color of the node
		-- BackColor = Background color of the node
		-- Prev = Previous Sibling
		-- Next = Next Sibling
		-- Parent = Parent
		-- Row = Row of the task in the task Grid (nil if task is not visible)
		-- taskTreeObj = main task tree GUI object to which this node belongs to
		-- Planning = Contains the planning mode schedule for the task if the task schedule planning is going on.
		
		-- Set task Tree internal as the metatable for exposed task tree empty table so we can catch all accesses to the task tree table and take actions appropriately
		setmetatable(taskTree, taskTreeINT)
		-- Metatable to access taskTreeINT for any missing keys
		setmetatable(taskTreeINT[taskTree],{__index=taskTreeINT})

		local oTree = taskTreeINT[taskTree]
		local ID = Karm.NewID()
		oTree.horSplitWin = wx.wxSplitterWindow(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxSP_3D, "Task Splitter")
		IDMap[ID] = taskTree
		-- wx.wxSize(Karm.GUI.initFrameW, 0.7*Karm.GUI.initFrameH)
		if not noTaskTree then
			oTree.horSplitWin:SetMinimumPaneSize(10)
		end

		ID = Karm.NewID()		
		oTree.treeGrid = wx.wxGrid(oTree.horSplitWin, ID, wx.wxDefaultPosition, 
						wx.wxDefaultSize, 0, "Task Tree Grid")
		IDMap[ID] = taskTree
	    oTree.treeGrid:CreateGrid(1,2)
	    oTree.treeGrid:SetColFormatBool(0)
	    oTree.treeGrid:SetRowLabelSize(15)
	    oTree.treeGrid:SetColLabelValue(0," ")
	    oTree.treeGrid:SetColLabelValue(1,"Tasks")
	    --Karm.GUI.treeGrid:SetCellHighlightPenWidth(0)
	    oTree.treeGrid:EnableGridLines(false)
	
		ID = Karm.NewID()
		oTree.ganttGrid = wx.wxGrid(oTree.horSplitWin, ID, wx.wxDefaultPosition, 
							wx.wxDefaultSize, 0, "Gantt Chart Grid")
		IDMap[ID] = taskTree
	    oTree.ganttGrid:CreateGrid(1,1)
	    oTree.ganttGrid:EnableGridLines(false)
	    -- Karm.GUI.ganttGrid:SetRowLabelSize(0)
	
		oTree.horSplitWin:SplitVertically(oTree.treeGrid, oTree.ganttGrid)
		if not noTaskTree then
			oTree.horSplitWin:SetSashPosition(0.3*parent:GetSize():GetWidth())
		else
			oTree.horSplitWin:Unsplit(oTree.treeGrid)
		end

		-- **************************EVENTS*******************************************
		-- SYNC THE SCROLLING OF THE TWO GRIDS	
		-- Create the scroll event to sync the 2 scroll bars in the wxScrolledWindow
		local f = onScrollTree(taskTree)
		--local f = onScTree
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_TOP, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_BOTTOM, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_PAGEUP, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_PAGEDOWN, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, f)
	
		f = onScrollGantt(taskTree)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_TOP, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_BOTTOM, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_PAGEUP, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_PAGEDOWN, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, f)
		oTree.ganttGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, f)
		
		-- Row Resize event
		f = onRowResizeTree(taskTree)
		oTree.treeGrid:Connect(wx.wxEVT_GRID_ROW_SIZE,f)
		f = onRowResizeGantt(taskTree)
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_ROW_SIZE,f)
		
		-- The TreeGrid label click event
		oTree.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,labelClick)
		--Karm.GUI.treeGrid:GetEventHandler():Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,Karm.GUI.taskDblClick)
		
		-- The GanttGrid label click event
		oTree.ganttGrid:GetEventHandler():Connect(wx.wxEVT_GRID_LABEL_LEFT_CLICK,ganttLabelClick)

		-- Gantt Grid Cell left click event
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,ganttCellClick)
		
		-- Gantt Cell double click event
		oTree.ganttGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_DCLICK,ganttCellDblClick)
		
		-- TreeGrid left click on cell event
		oTree.treeGrid:Connect(wx.wxEVT_GRID_CELL_LEFT_CLICK,cellClick)
		
		-- Sash position changing event
		oTree.horSplitWin:Connect(wx.wxEVT_COMMAND_SPLITTER_SASH_POS_CHANGED, horSashAdjust)

		-- Splitter resize event
		oTree.horSplitWin:Connect(wx.wxEVT_SIZE, widgetResize)
	
		return taskTree
	end
	
	function nodeMeta.MakeVisible(node)
		local currNode = node
		if not nodeMeta[currNode] then
			return nil
		end
		while nodeMeta[currNode].Parent and not nodeMeta[currNode].Row do
			currNode = nodeMeta[currNode].Parent
			currNode.Expanded = true
		end
		return true
	end
	
	function nodeMeta.__index(tab,key)
		-- function to catch all accesses to a node object
		if key == "MakeVisible" then
			return nodeMeta.MakeVisible
		elseif key == "ID" then
			return nodeMeta	-- To identify node objects
		else
			return nodeMeta[tab][key]
		end
	end
	
	function nodeMeta.__newindex(tab,key,val)
		-- function to catch all setting commands to taskTree nodes
		
		-- define object references to bypass metamethod calls
		local oTree = taskTreeINT[nodeMeta[tab].taskTreeObj]
		local oNode = nodeMeta[tab]
		
		if key == "Expanded" then
			if oNode.Expanded and not val then
				-- Check if updates are enabled
				if oTree.update then
					if oNode.Row then
						-- Task is visible on the GUI
						-- Collapse this node in the GUI here
						local nextNode = nil
						local rows
						local currNode
						if oNode.Next then
							-- Number of rows to collapse
							rows = oNode.Next.Row - oNode.Row - 1
							-- Decrement the rows of subsequent tasks
							nextNode = oNode.Next
							while nextNode do
								nextNode.Row = nextNode.Row - rows 
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
							end
							nextNode = oNode.Next
						else
							-- Since there is no sibling the row collapsing will affect the ancestor which has siblings
							-- Find that ancestor:
							currNode = oNode.Parent
							while currNode and (not currNode.Next) do
								currNode = currNode.Parent
							end
							if currNode then
								nextNode = currNode.Next
								rows = nextNode.Row - oNode.Row - 1
								-- Decrement the rows of subsequent tasks
								while nextNode do
									nextNode.Row = nextNode.Row - rows 
									nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
								end
								nextNode = currNode.Next
							else
								rows = oTree.treeGrid:GetNumberRows() - oNode.Row
							end
						end
						-- Make nil the Row index of all children in the hierarchy of tab
						currNode = oTree.Nodes[taskTreeINT.nextNode(oNode.taskTreeObj,oNode.Key)]
						while currNode ~= nextNode do
							currNode.Row = nil
							currNode = oTree.Nodes[taskTreeINT.nextNode(currNode.taskTreeObj,currNode.Key)]
						end
						-- Adjust the row labels
						if nextNode then
							for i = nextNode.Row+rows,oTree.treeGrid:GetNumberRows() do
								oTree.treeGrid:SetRowLabelValue(i-rows-1,oTree.treeGrid:GetRowLabelValue(i-1))
								oTree.ganttGrid:SetRowLabelValue(i-rows-1,oTree.ganttGrid:GetRowLabelValue(i-1))
							end		
						end			
						-- Now delete all the rows
						oTree.treeGrid:DeleteRows(oNode.Row,rows)
						oTree.ganttGrid:DeleteRows(oNode.Row,rows)
						oTree.treeGrid:SetRowLabelValue(oNode.Row-1,"+")
						if #oTree.Selected > 0 then
							local i = 0
							while i < #oTree.Selected do
								i = i + 1
								if not oTree.Selected[i].Row then
									-- The selected node is not visible anymore
									for j = i + 1,#oTree.Selected do
										oTree.Selected[j-1] = oTree.Selected[j]
									end
									oTree.Selected[#oTree.Selected] = nil
								end
							end
							if #oTree.Selected == 0 then
								oTree.Selected[1] = tab
								oTree.Selected.Latest = 1
								tab.Selected = true
								if oTree.cellClickCallBack then
									oTree.cellClickCallBack(oNode.Task)
								end
							end
						end
					end
					-- Expanded was true and now making it false
					oNode.Expanded = nil
				else
					oTree.actionQ[#oTree.actionQ + 1] = "taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Expanded = nil"
				end		-- if oTree.update then ends
			elseif not oNode.Expanded and val then
				-- Check if updates are enabled
				if oTree.update then
					if oNode.Row and oNode.Children > 0 then
						-- Task is visible on the GUI
						-- Expand the node in the GUI here
						-- Number of rows to insert
						local rows = oNode.Children
						-- Increment the rows of subsequent tasks
						local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(oNode.taskTreeObj,oNode.Key)]
						while nextNode do
							nextNode.Row = nextNode.Row + rows 
							nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(nextNode.taskTreeObj,nextNode.Key)]
						end
						-- Now insert the child rows here
						-- Find the hierarchy level
						local hierLevel = -1
						nextNode = oNode.FirstChild
						while nextNode do
							hierLevel = hierLevel + 1
							nextNode = nextNode.Parent
						end			
						nextNode = oNode.FirstChild
						local currRow = oNode.Row
						while nextNode do
							currRow = currRow + 1
							nextNode.Row = currRow
							dispTask(oNode.taskTreeObj,nextNode.Row,true,nextNode,hierLevel)
							dispGantt(oNode.taskTreeObj,nextNode.Row,true,nextNode)
							nextNode = nextNode.Next
						end
						oTree.treeGrid:SetRowLabelValue(oNode.Row-1,"-")
						-- Expanded was false and now making it true
						oNode.Expanded = true
						-- Now check if any of the exposed children have expanded true
						nextNode = oNode.FirstChild
						local toExpand = {}
						while nextNode do
							if nextNode.Expanded then
								nodeMeta[nextNode].Expanded = nil
								toExpand[#toExpand + 1] = nextNode
							end
							nextNode = nextNode.Next
						end
						-- Perform expansion of child nodes if any
						for i = 1,#toExpand do
							toExpand[i].Expanded = true
						end
					else
						-- Expanded was false and now making it true
						oNode.Expanded = true
					end
				else
					oTree.actionQ[#oTree.actionQ + 1] = "taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Expanded = true"
				end		-- if oTree.update then ends
			end		-- if oNode.Expanded and not val then ends
		elseif key == "Selected" then
			if oNode.Selected and not val then
				-- Selected was true and now making it false
				oNode.Selected = nil
				-- Unselect this node in the GUI
				oTree.Selected = {}
				oTree.treeGrid:SetGridCursor(0,0)
			elseif not oNode.Selected and val then
				-- Selected was false and now making it true
				oNode.Selected = true
				-- Select the node in the GUI here
				oTree.Selected = {tab,Latest = 1}
				oTree.treeGrid:SetGridCursor(oNode.Row-1,1)
			end	
		elseif key == "ForeColor" or key == "BackColor" then
			if type(val) == "table" and val.Red and type(val.Red) == "number" and val.Green and type(val.Green) == "number" and
			  val.Blue and type(val.Blue) == "number" then
				if oTree.update then
					oNode[key] = val
					if oNode.Row then
						-- Calculate the hierLevel
						local hierLevel = 0
						local currNode = tab
						while nodeMeta[currNode].Parent do
							hierLevel = hierLevel + 1
							currNode = nodeMeta[currNode].Parent
						end
	
						dispTask(nodeMeta[tab].taskTreeObj,nodeMeta[tab].Row,false,tab,hierLevel)
					end
				else
					oTree.actionQ[#oTree.actionQ + 1] = "nodeMeta[taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."]]."..key.."={Red="..val.Red..",Green="..val.Green..",Blue="..val.Blue.."}"
					oTree.actionQ[#oTree.actionQ + 1] = "if ".."taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."].Row then local hierLevel = 0 local currNode = ".."taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."] while nodeMeta[currNode].Parent do hierLevel = hierLevel + 1 currNode = nodeMeta[currNode].Parent end dispTask(tab,nodeMeta[taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."]].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",oNode.Key).."],hierLevel) end"
				end		-- if oTree.update then ends
			end					
		else
			oNode[key] = val
		end		-- if key == ?? ends here
	end		-- function nodeMeta.__newindex(tab,key,val) ends

	function taskTreeINT.__index(tab,key)
		-- function to catch all accesses to taskTree
		return taskTreeINT[tab][key]
	end
	
	function taskTreeINT.__newindex(tab,key,val)
		-- function to catch all setting commands to Karm.GUI.taskTree
		-- object reference to bypass metamethod
		local oTree = taskTreeINT[tab]
		if key == "update" then
			if oTree.update and not val then
				-- Update was true and now making it false
				oTree.update = false
			elseif not oTree.update and val then
				oTree.update = true
				-- Now do the actionQ
				local env = getfenv(1)
				-- Write the up Values
				-- These values need to be passed to the environment since they are up values and the loadstring function does not have them
				-- So we just pass the values tot he environment and then remove them after executing the string
				local passToEnv = {["taskTreeINT"]=taskTreeINT,["tab"]=tab,["nodeMeta"]=nodeMeta,["dispTask"]=dispTask,["dispGantt"]=dispGantt}
				for k,v in pairs(passToEnv) do
					if env[k] then
						passToEnv[k] = nil
					else
						env[k] = v
					end
				end
				--print(taskTreeINT)
				for i = 1,#oTree.actionQ do
					local f = loadstring(oTree.actionQ[i])
					setfenv(f,env)
					f()
				end
				-- Remove from env
				for k,v in pairs(passToEnv) do
					env[k] = nil
				end
				-- Clear all pending actions
				oTree.actionQ = {}
			end
		elseif key == "Planning" then
			-- do nothing user cannot modify this
		elseif key == "taskList" then
			-- do nothing user cannot modify this
		elseif key == "Selected" then
			-- do nothing user cannot modify this
		elseif key == "UpdateKeys" then
			-- do nothing user cannot modify this
		elseif key == "SwapUpdateKeys" then
			-- do nothing user cannot modify this
		else
			oTree[key] = val
		end
	end
	
	function taskTreeINT.Clear(tab)
		taskTreeINT[tab].Nodes = {}
		taskTreeINT[tab].nodeCount = 0
		taskTreeINT[tab].Roots = {}
		taskTreeINT[tab].actionQ = {}
		taskTreeINT[tab].treeGrid:DeleteRows(0,taskTreeINT[tab].treeGrid:GetNumberRows())
		taskTreeINT[tab].ganttGrid:DeleteRows(0,taskTreeINT[tab].ganttGrid:GetNumberRows())
	end
		
	local function refreshGanttFunc(taskTree)
		-- Erase the previous data
		taskTreeINT[taskTree].ganttGrid:DeleteRows(0,taskTreeINT[taskTree].ganttGrid:GetNumberRows())
		local rowPtr = 0
		local hierLevel = 0
		for i,v in taskTreeINT.tvpairs(taskTree) do
			dispGantt(taskTree,rowPtr+1,true,v)
			rowPtr = rowPtr + 1
		end		-- Looping through all the nodes ends	
	end
	
	refreshGantt = refreshGanttFunc
	
	-- row begins with 1 as the 1st row of the spreadsheet
	local function dispTaskFunc(taskTree,row, createRow, taskNode, hierLevel)
		if (createRow and taskTreeINT[taskTree].treeGrid:GetNumberRows()<row-1) then
			return nil
		end
		if not createRow and taskTreeINT[taskTree].treeGrid:GetNumberRows()<row then
			return nil
		end
		if createRow then
			taskTreeINT[taskTree].treeGrid:InsertRows(row-1)
			-- Now shift the row labels
			for i = taskTreeINT[taskTree].treeGrid:GetNumberRows()-1,row,-1 do
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(i,taskTreeINT[taskTree].treeGrid:GetRowLabelValue(i-1))
			end
		end
		taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,1,string.rep(" ",hierLevel*4)..taskNode.Title)
		taskTreeINT[taskTree].treeGrid:SetCellAlignment(row-1,1,wx.wxALIGN_LEFT, wx.wxALIGN_CENTRE)
		if taskNode.Children > 0 then
			if taskNode.Expanded then
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1,"-")
			else
				taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1,"+")
			end
		else
			taskTreeINT[taskTree].treeGrid:SetRowLabelValue(row-1," ")
		end
		if taskNode.Task and taskNode.Task.Status and string.upper(taskNode.Task.Status) == "DONE" then
			taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,0,"1")
		else
			taskTreeINT[taskTree].treeGrid:SetCellValue(row-1,0,"0")
		end
		taskTreeINT[taskTree].treeGrid:SetReadOnly(row-1,0)
		taskTreeINT[taskTree].treeGrid:SetReadOnly(row-1,1)
		-- Set the back ground color
		if taskNode.BackColor then
			taskTreeINT[taskTree].treeGrid:SetCellBackgroundColour(row-1,1,wx.wxColour(taskNode.BackColor.Red,taskNode.BackColor.Green,taskNode.BackColor.Blue))
		end
		if taskNode.ForeColor then
			taskTreeINT[taskTree].treeGrid:SetCellTextColour(row-1,1,wx.wxColour(taskNode.ForeColor.Red,taskNode.ForeColor.Green,taskNode.ForeColor.Blue))
		end
		taskTreeINT[taskTree].treeGrid:ForceRefresh()
	end
	
	dispTask = dispTaskFunc
	
	-- row begins with 1 as the 1st row of the spreadsheet
	local function dispGanttFunc(taskTree,row,createRow,taskNode)
		if (createRow and taskTreeINT[taskTree].ganttGrid:GetNumberRows()<row-1) then
			return nil
		end
		if not createRow and taskTreeINT[taskTree].ganttGrid:GetNumberRows()<row then
			return nil
		end
		if createRow then
			taskTreeINT[taskTree].ganttGrid:InsertRows(row-1)
			-- Now shift the row labels
			for i = taskTreeINT[taskTree].ganttGrid:GetNumberRows(),row,-1 do
				taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(i,taskTreeINT[taskTree].ganttGrid:GetRowLabelValue(i-1))
			end
		end
		-- Now update the ganttGrid to include the schedule
		local startDay = Karm.Utility.toXMLDate(taskTreeINT[taskTree].startDate:Format("%m/%d/%Y"))
		local finDay = Karm.Utility.toXMLDate(taskTreeINT[taskTree].finDate:Format("%m/%d/%Y"))
		local days = taskTreeINT[taskTree].ganttGrid:GetNumberCols()
		--print(Karm.Utility.getWeekDay(startDay))
		if not taskNode.Task then
			-- No task associated with the node so color the cells to show no schedule
			taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"X")
			local currDate = Karm.Utility.XMLDate2wxDateTime(startDay)
			for i = 1,days do
				--print(currDate:Format("%m/%d/%Y"),Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))))
				if Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
					local newColor = {Red=Karm.GUI.noScheduleColor.Red - Karm.GUI.sunDayOffset.Red,Green=Karm.GUI.noScheduleColor.Green - Karm.GUI.sunDayOffset.Green,
					Blue=Karm.GUI.noScheduleColor.Blue-Karm.GUI.sunDayOffset.Blue}
					if newColor.Red < 0 then newColor.Red = 0 end
					if newColor.Green < 0 then newColor.Green = 0 end
					if newColor.Blue < 0 then newColor.Blue = 0 end
					taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
				else
					taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(Karm.GUI.noScheduleColor.Red,
						Karm.GUI.noScheduleColor.Green,Karm.GUI.noScheduleColor.Blue))
				end
				taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
				currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
				taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
			end
		else
			-- Task exists so create the schedule
			--Get the datelist
			-- Check if planning mode for this task
			local planning = nil
			if taskTreeINT[taskTree].Planning then
				for i = 1,#taskTreeINT[taskTree].taskList do
					if taskTreeINT[taskTree].taskList[i] == taskNode.Task then
						-- This is a planning mode task
						planning = true
						break
					end
				end
			end
			local dateList
			if taskTreeINT[taskTree].ShowActual then
				dateList = Karm.TaskObject.getWorkDates(taskNode.Task,taskTreeINT[taskTree].Bubble)
			else
				dateList = Karm.TaskObject.getDates(taskNode.Task,taskTreeINT[taskTree].Bubble, planning)
			end
			if not dateList then
				-- No task associated with the node or no schedule so color the cells to show no schedule
				if planning then
					taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"(P)X")
				else
					taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,"X")
				end
				local currDate = Karm.Utility.XMLDate2wxDateTime(startDay)
				for i = 1,days do
					if Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
						local newColor = {Red=Karm.GUI.noScheduleColor.Red - Karm.GUI.sunDayOffset.Red,Green=Karm.GUI.noScheduleColor.Green - Karm.GUI.sunDayOffset.Green,
						Blue=Karm.GUI.noScheduleColor.Blue-Karm.GUI.sunDayOffset.Blue}
						if newColor.Red < 0 then newColor.Red = 0 end
						if newColor.Green < 0 then newColor.Green = 0 end
						if newColor.Blue < 0 then newColor.Blue = 0 end
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
					else
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(Karm.GUI.noScheduleColor.Red,
							Karm.GUI.noScheduleColor.Green,Karm.GUI.noScheduleColor.Blue))
					end
					taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
					currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
					taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
				end
			else
				-- Some dates are scheduled for the task
				local map
				if planning then
					map = {Estimate="(P)E",Commit = "(P)C", Revs = "(P)R", Actual = "(P)A"}
				else
					map = {Estimate="E",Commit = "C", Revs = "R", Actual = "A"}
				end
				-- Erase the previous schedule on the row
				local currDate = Karm.Utility.XMLDate2wxDateTime(startDay)
				for i=1,days do
					if Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
						local newColor = {Red=Karm.GUI.emptyDayColor.Red - Karm.GUI.sunDayOffset.Red,Green=Karm.GUI.emptyDayColor.Green - Karm.GUI.sunDayOffset.Green,
						Blue=Karm.GUI.emptyDayColor.Blue-Karm.GUI.sunDayOffset.Blue}
						if newColor.Red < 0 then newColor.Red = 0 end
						if newColor.Green < 0 then newColor.Green = 0 end
						if newColor.Blue < 0 then newColor.Blue = 0 end
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
					else
						taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,i-1,wx.wxColour(Karm.GUI.emptyDayColor.Red,
							Karm.GUI.emptyDayColor.Green,Karm.GUI.emptyDayColor.Blue))
					end
					taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,i-1,"")
					currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
					taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,i-1)
				end		
				local before,after
				for i=1,#dateList do
					currDate = Karm.Utility.XMLDate2wxDateTime(dateList[i].Date)
					if dateList[i].Date>=startDay and dateList[i].Date<=finDay then
						-- This date is in range find the column which needs to be highlighted
						local col = 0					
						local stepDate = Karm.Utility.XMLDate2wxDateTime(startDay)
						while not stepDate:IsSameDate(currDate) do
							stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
							col = col + 1
						end
						--taskTreeINT[taskTree].startDate:Subtract(wx.wxDateSpan(0,0,0,col))
						if Karm.Utility.getWeekDay(Karm.Utility.toXMLDate(currDate:Format("%m/%d/%Y"))) == "Sunday" then
							local newColor = {Red=dateList[i].BackColor.Red - Karm.GUI.sunDayOffset.Red,
							  Green=dateList[i].BackColor.Green - Karm.GUI.sunDayOffset.Green,
							  Blue=dateList[i].BackColor.Blue-Karm.GUI.sunDayOffset.Blue}
							if newColor.Red < 0 then newColor.Red = 0 end
							if newColor.Green < 0 then newColor.Green = 0 end
							if newColor.Blue < 0 then newColor.Blue = 0 end
							taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(newColor.Red,newColor.Green,newColor.Blue))
						else
							taskTreeINT[taskTree].ganttGrid:SetCellBackgroundColour(row-1,col,wx.wxColour(dateList[i].BackColor.Red,
								dateList[i].BackColor.Green,dateList[i].BackColor.Blue))
						end
						taskTreeINT[taskTree].ganttGrid:SetCellTextColour(row-1,col,wx.wxColour(dateList[i].ForeColor.Red,dateList[i].ForeColor.Green,dateList[i].ForeColor.Blue))
						taskTreeINT[taskTree].ganttGrid:SetCellValue(row-1,col,dateList[i].Text)
						taskTreeINT[taskTree].ganttGrid:SetReadOnly(row-1,col)
					else
						if dateList[i].Date<startDay then
							before = true
						end
						if dateList[i].Date>finDay then
							after = true
						end
					end		-- if dateList[i]>=startDay and dateList[i]<=finDay then ends
				end		-- for i=1,#dateList do ends
				local str = ""
				if before then
					str = "<"
				end
				if after then
					str = str..">"
				end
				taskTreeINT[taskTree].ganttGrid:SetRowLabelValue(row-1,map[dateList.typeSchedule]..tostring(dateList.index)..str)
			end		-- if not dateList then ends
		end	
		taskTreeINT[taskTree].ganttGrid:ForceRefresh()
	end		-- local function dispGanttFunc(taskTree,row,createRow,taskNode) ends
	
	dispGantt = dispGanttFunc
	
	-- Updates the keys of a node from the underlying tasks
	function taskTreeINT.UpdateKeys(taskTree,node,noRecurse)
		if node.ID ~= nodeMeta then
			error("Need valid node objects to UpdateKeys.",2)
		end
		if not nodeMeta[node].Task then
			error("Need a node with an associated task to update the key.",2)
		end
		local currNode = node
		local oTree = taskTreeINT[taskTree]
		oTree.Nodes[nodeMeta[currNode].Key]  = nil
		nodeMeta[currNode].Key = nodeMeta[currNode].Task.TaskID
		oTree.Nodes[nodeMeta[currNode].Key] = currNode
		if noRecurse then
			return
		end
		if nodeMeta[currNode].FirstChild then
			currNode = nodeMeta[currNode].FirstChild
			while currNode ~= node do
				oTree.Nodes[nodeMeta[currNode].Key]  = nil
				nodeMeta[currNode].Key = nodeMeta[currNode].Task.TaskID
				oTree.Nodes[nodeMeta[currNode].Key] = currNode
				if nodeMeta[currNode].FirstChild then
					currNode = nodeMeta[currNode].FirstChild
				elseif nodeMeta[currNode].Next then
					currNode = nodeMeta[currNode].Next
				else
					while currNode ~= node and not nodeMeta[currNode].Next do
						currNode = nodeMeta[currNode].Parent
					end
					if currNode == node then 
						break
					end
					currNode = nodeMeta[currNode].Next
				end		-- if nodeMeta[currNode].FirstChild then ends here
			end		-- while currNode ~= node do ends
		end		-- if nodeMeta[currNode].FirstChild then ends		
	end
	
	-- Function to swap the keys of the given 2 node hierarchies. They keys are still taken from the taskIDs for task swap
	-- The function just assumes that there would eb key swapping happenning so uses a 3rd storage element to make the swap
	-- happen and make data consistent in the Nodes table (Where each node is accessible from its key)
	function taskTreeINT.SwapUpdateKeys(taskTree,node1,node2)
		if getmetatable(node1)~=nodeMeta or getmetatable(node2)~=nodeMeta then
			error("Need valid node objects to SwapKeys.",2)
		end
		if (not nodeMeta[node1].Task and nodeMeta[node2].Task) or (not nodeMeta[node2].Task and nodeMeta[node1].Task) then
			error("Cannot Swap Keys between a Spore and task.",2)
		end
		local oTree = taskTreeINT[taskTree]
		-- Check if these are spore nodes
		if nodeMeta[node1].Key:sub(1,#Karm.Globals.ROOTKEY)==Karm.Globals.ROOTKEY then
			-- ################################################################################
			-- QUESTIONALBLE SINCE SPORE KEYS ARE BASED ON THEIR FILE NAMES!
			-- ################################################################################
			-- These are spores
			-- Just swap the spore keys
			nodeMeta[node1].Key, nodeMeta[node2].Key = nodeMeta[node2].Key, nodeMeta[node1].Key
			oTree.Nodes[nodeMeta[node1].Key] = node1
			oTree.Nodes[nodeMeta[node2].Key] = node2
		else
			-- Move the node1 hierarchy out of Nodes table
			local node1Hier = {}
			local currNode = node1
			node1Hier[nodeMeta[node1].Key] = node1
			oTree.Nodes[nodeMeta[node1].Key]  = nil
			if nodeMeta[currNode].FirstChild then
				currNode = nodeMeta[currNode].FirstChild
				while currNode ~= node1 do
					node1Hier[nodeMeta[currNode].Key] = currNode
					oTree.Nodes[nodeMeta[currNode].Key]  = nil
					if nodeMeta[currNode].FirstChild then
						currNode = nodeMeta[currNode].FirstChild
					elseif nodeMeta[currNode].Next then
						currNode = nodeMeta[currNode].Next
					else
						while currNode ~= node1 and not nodeMeta[currNode].Next do
							currNode = nodeMeta[currNode].Parent
						end
						if currNode == node1 then 
							break
						end
					end		-- if nodeMeta[currNode].FirstChild then ends here
				end		-- while currNode ~= node1 do ends
			end		-- if nodeMeta[currNode].FirstChild then ends
			-- Now convert node2 hierarchy to the proper Keys
			taskTreeINT.UpdateKeys(taskTree,node2)
			-- Now add the node1 nodes back with the correct keys
			for k,v in pairs(node1Hier) do
				nodeMeta[v].Key = nodeMeta[v].Task.TaskID
				oTree.Nodes[nodeMeta[v].Key] = v
			end
		end		-- if not nodeMeta[node1].Task then ends
	end

	-- Refreshes a node with the key same as the given task's TaskID
	-- This is a total refresh of the task name and also the schedule
	function taskTreeINT.RefreshNode(taskTree,task)
		return taskTreeINT.UpdateNode(taskTree,task)
	end
	
	function taskTreeINT.UpdateNode(taskTree,task)
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[task.TaskID]
		
		if not node then
			return nil
		end
		
		nodeMeta[node].Task = task
		nodeMeta[node].Title = task.Title
		
		if nodeMeta[node].Row then
			-- Calculate the hierLevel
			local hierLevel = 0
			local currNode = node
			while nodeMeta[currNode].Parent do
				hierLevel = hierLevel + 1
				currNode = nodeMeta[currNode].Parent
			end
	
			if oTree.update then
				dispTask(taskTree,nodeMeta[node].Row,false,node,hierLevel)
				dispGantt(taskTree,nodeMeta[node].Row,false,node)
				if #oTree.Selected > 0 then
					oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
				end
			else
				-- Add to actionQ
				oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
					string.format("%q",task.TaskID).."].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",task.TaskID).."],"..tostring(hierLevel)..")"
				oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes["..
					string.format("%q",task.TaskID).."].Row,false,taskTreeINT[tab].Nodes["..string.format("%q",task.TaskID).."])"				
				oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
			end
		end		-- if nodeMeta[node].Row then ends
	end
	
	function taskTreeINT.DeleteTree(taskTree,Key)
		if Key == Karm.Globals.ROOTKEY then
			error("DeleteTree: Function cannot be used to delete a Root node,",2)
		end
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[Key]
		if not node then
			-- Already deleted
			return
		end
		local parent = nodeMeta[node].Parent
		local nodesToDel = {node}
		local rowsToDel = {nodeMeta[node].Row}
		-- Make list of nodes and rows to delete
		local k, nextNode = taskTree:nextNode(Key)
		while nextNode do
			-- Check if this is in the child hierarchy for node
			local inHier = nil
			local currNode = nextNode
			while currNode and not inHier do
				if nodeMeta[currNode].Parent == node then
					-- In the child hierarchy
					inHier = true
				end
				currNode = nodeMeta[currNode].Parent
			end
			if not inHier then
				break	-- once a hierarchy is exited there cannot be another following node in the hierarchy
			end
			-- Add to the delete list
			nodesToDel[#nodesToDel + 1] = nextNode
			rowsToDel[#rowsToDel + 1] = nodeMeta[nextNode].Row
			k, nextNode = taskTree:nextNode(k)
		end		-- while nextNode do ends
		-- Update the links
		if nodeMeta[node].Prev then
			nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
		end
		if nodeMeta[node].Next then
			nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
		end
		-- Parent links
		nodeMeta[parent].Children = nodeMeta[parent].Children - 1
		if not nodeMeta[node].Prev then
			-- This was the first child
			nodeMeta[parent].FirstChild = nodeMeta[node].Next
		end
		if not nodeMeta[node].Next then
			-- This was the last child
			nodeMeta[parent].LastChild = nodeMeta[node].Prev
		end
		
		if nextNode then
			-- Adjust the row labels
			if not nodeMeta[nextNode].Row then
				k,nextNode = taskTree:nextVisibleNode(k)
			end
			local nextStartNode = nextNode
			while nextNode do
				oTree.treeGrid:SetRowLabelValue(nodeMeta[nextNode].Row-#rowsToDel-1,oTree.treeGrid:GetRowLabelValue(nodeMeta[nextNode].Row-1))
				oTree.ganttGrid:SetRowLabelValue(nodeMeta[nextNode].Row-#rowsToDel-1,oTree.ganttGrid:GetRowLabelValue(nodeMeta[nextNode].Row-1))
				-- Update the node Row
				nodeMeta[nextNode].Row = nodeMeta[nextNode].Row-#rowsToDel
				k,nextNode = taskTree:nextVisibleNode(k)
			end
		end	
		-- Update the parent row label
		if nodeMeta[parent].Children == 0 then
			oTree.treeGrid:SetRowLabelValue(nodeMeta[nodeMeta[node].Parent].Row-1,"")
			nodeMeta[parent].Expanded = false
		end
		-- Now delete everything
		-- Delete the nodes
		for i = 1,#nodesToDel do
			oTree.Nodes[nodeMeta[nodesToDel[i]].Key] = nil
			nodeMeta[nodesToDel[i]] = nil
		end
		oTree.nodeCount = oTree.nodeCount - #nodesToDel
		
		-- Delete the rows
		for i = 1,#rowsToDel do
			oTree.treeGrid:DeleteRows(rowsToDel[i]-1)
			oTree.ganttGrid:DeleteRows(rowsToDel[i]-1)
			-- Adjust the row numbers to account for deleted row	
			for j = i + 1,#rowsToDel do	
				if rowsToDel[j] > rowsToDel[i] then
					rowsToDel[j] = rowsToDel[j] - 1
				end
			end
		end
		
		-- Remove the nodes from the Selected list
		if #oTree.Selected > 0 then
			local i = 1
			while i <= #oTree.Selected do
				for j = 1,#nodesToDel do
					if oTree.Selected[i] == nodesToDel[j] then
						for k = i+1,#oTree.Selected-1 do
							oTree.Selected[k-1] = oTree.Selected[k]
						end
						oTree.Selected[#oTree.Selected] = nil
						break
					end
				end
				i = i + 1
			end
			if #oTree.Selected == 0 then
				oTree.Selected[1] = parent
				oTree.Selected.Latest = 1
				parent.Selected = true
				if oTree.cellClickCallBack then
					oTree.cellClickCallBack(parent.Task)
				end
			else
				if oTree.Selected.Latest > #oTree.Selected then
					oTree.Selected.Lates = #oTree.Selected
				end
			end
		end
	end		-- function taskTreeINT.DeleteTree(taskTree,Key) ends
	
	function taskTreeINT.DeleteSubUpdate(taskTree,Key)
		if Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			error("DeleteSubUpdate: Function cannot be used to delete a spore or Root node.",2)
		end
		local oTree = taskTreeINT[taskTree]
		local node = oTree.Nodes[Key]
		local parent = nodeMeta[node].Parent
		-- Expand the node first
		node.Expanded = true
		-- Update the row numbers of all subsequent tasks first
		local key,nextNode = taskTree:nextVisibleNode(Key)
		local nextV = nextNode
		while nextNode do
			-- Check if this is in the child hierarchy for node
			local inHier = nil
			local currNode = nextNode
			while currNode and not inHier do
				if nodeMeta[currNode].Parent == node then
					-- In the child hierarchy
					inHier = true
				end
				currNode = nodeMeta[currNode].Parent
			end
			if inHier then
				-- Update the display of the task
				-- Calculate the hierLevel
				local hierLevel = -1
				local cN = nextNode
				while nodeMeta[cN].Parent do
					hierLevel = hierLevel + 1
					cN = nodeMeta[cN].Parent
				end
		
				if oTree.update then
					dispTask(taskTree,nodeMeta[nextNode].Row,false,nextNode,hierLevel)
					dispGantt(taskTree,nodeMeta[nextNode].Row,false,nextNode)
					if #oTree.Selected > 0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes['"..
						string.format("%q",nodeMeta[nextNode].Key).."'].Row,false,taskTreeINT[tab].Nodes['"..string.format("%q",nodeMeta[nextNode].Key).."'],"..tostring(hierLevel)..")"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes['"..
						string.format("%q",nodeMeta[nextNode].Key).."'].Row,false,taskTreeINT[tab].Nodes['"..string.format("%q",nodeMeta[nextNode].Key).."'])"				
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
				end
			end
			-- Update the row now since this will be the new row after the node row is deleted
			nodeMeta[nextNode].Row = nodeMeta[nextNode].Row - 1
			key, nextNode = taskTree:nextVisibleNode(key)
		end		-- while nextNode do ends
		
		-- Update the parent of all the immediate children and the hierLevel of all children hierarchy
		local currNode = nodeMeta[node].FirstChild
		while currNode do		
			-- Update the parent
			nodeMeta[currNode].Parent = parent
			currNode = nodeMeta[currNode].Next
		end

		-- Update the Parent links for the node
		nodeMeta[parent].Children = nodeMeta[parent].Children + nodeMeta[node].Children - 1
		if not nodeMeta[node].Prev then
			-- The FirstChild is changing
			if nodeMeta[node].FirstChild then
				nodeMeta[parent].FirstChild = nodeMeta[node].FirstChild
			else
				nodeMeta[parent].FirstChild = nodeMeta[node].Next
			end
		end
		if not nodeMeta[node].Next then
			-- The LastChild is changing
			if nodeMeta[node].LastChild then
				nodeMeta[parent].LastChild = nodeMeta[node].LastChild
			else
				nodeMeta[parent].LastChild = nodeMeta[node].Prev
			end
		end

		-- Update the sibling links of the node
		if nodeMeta[node].Prev then
			if nodeMeta[node].FirstChild then
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].FirstChild
				nodeMeta[nodeMeta[node].FirstChild].Prev = nodeMeta[node].Prev
			else
				nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
				if nodeMeta[node].Next then
					nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
				end
			end
		end
		if nodeMeta[node].Next then
			if nodeMeta[node].LastChild then
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].LastChild
				nodeMeta[nodeMeta[node].LastChild].Next = nodeMeta[node].Next
			else
				nodeMeta[nodeMeta[node].Next].Prev = nodeMeta[node].Prev
				if nodeMeta[node].Prev then
					nodeMeta[nodeMeta[node].Prev].Next = nodeMeta[node].Next
				end
			end
		end


		-- Adjust the row labels
		for i = nodeMeta[node].Row+1,oTree.treeGrid:GetNumberRows() do
			oTree.treeGrid:SetRowLabelValue(i-2,oTree.treeGrid:GetRowLabelValue(i-1))
			oTree.ganttGrid:SetRowLabelValue(i-2,oTree.ganttGrid:GetRowLabelValue(i-1))
		end		
		-- Finally delete the node row
		oTree.treeGrid:DeleteRows(nodeMeta[node].Row-1)
		oTree.ganttGrid:DeleteRows(nodeMeta[node].Row-1)
		-- Update the - sign on the parent
		if not nodeMeta[parent].FirstChild then
			-- Nothing left under the parent
			oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"")
		elseif not nodeMeta[nodeMeta[parent].FirstChild].Row then
			oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"+")
			nodeMeta[parent].Expanded = nil
		end
		-- Remove the node from the Selected list
		if #oTree.Selected > 0 then
			local index
			for i = 1,#oTree.Selected do
				if oTree.Selected[i] == node then
					index = i
					break
				end
			end
			if index then
				for i = index+1,#oTree.Selected-1 do
					oTree.Selected[i-1] = oTree.Selected[i]
				end
				oTree.Selected[#oTree.Selected] = nil
				if #oTree.Selected == 0 then
					if not nextV then
						nextV = parent
					end
					oTree.Selected[1] = nextV
					oTree.Selected.Latest = 1
					nextV.Selected = true
					if oTree.cellClickCallBack then
						oTree.cellClickCallBack(nextV.Task)
					end
				else
					if oTree.Selected.Latest > #oTree.Selected then
						oTree.Selected.Latest = #oTree.Selected
					end
				end
			end
		end
		-- Remove references to the node
		oTree.Nodes[nodeMeta[node].Key] = nil
		nodeMeta[node] = nil
		oTree.nodeCount = oTree.nodeCount - 1		
	end		-- function taskTreeINT.DeleteSubUpdate(taskTree,task) ends
	
	function taskTreeINT.AddNode(taskTree,nodeInfo)
		-- Add the node to the GUI task tree
		-- nodeInfo.Relative = relative of this new node (should be a task ID) (Can be nil - together with relation means root node)
		-- nodeInfo.Relation = relation of this new node to the Relative. This can be "Child", "Next Sibling", "Prev Sibling" (Can be nil)
		-- nodeInfo.Key = key by which this node is uniquely identified in the tree
		-- nodeInfo.Text = text to be visible to represent the node in the GUI
		-- nodeInfo.Task = Task to be associated with this node (Can be nil)
		
		local oTree = taskTreeINT[taskTree]
		-- First make sure the key is unique
		if oTree.Nodes[nodeInfo.Key] then
			-- Key already exists
			wx.wxMessageBox("Trying to add a duplicate Key ("..nodeInfo.Key..") to the task Tree.",
		                wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
			return nil
		end
		-- Check if Relative exist
		if nodeInfo.Relative then
			if not oTree.Nodes[nodeInfo.Relative] then
				-- Relative specified but does not exist
				wx.wxMessageBox("Specified relative does not exist ("..nodeInfo.Relative..") in the task Tree.",
			                wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
				return nil
			end
			-- Since relative is specified relation should be specified
			if not nodeInfo.Relation then
				-- Relative specified but Relation not specified
				wx.wxMessageBox("No relation specified for task (".. nodeInfo.Text..").",
			                wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
				return nil
			end
		end
		-- Check if Relation if correct
		if nodeInfo.Relation then
			if string.upper(nodeInfo.Relation) ~= "CHILD" and string.upper(nodeInfo.Relation) ~= "NEXT SIBLING" and string.upper(nodeInfo.Relation) ~= "PREV SIBLING" then
				-- Relation specified incorrectly 
				wx.wxMessageBox("Specified relation is not correct ("..nodeInfo.Relation.."). Allowed values are 'Child', 'Next Sibling', 'Prev Sibling'.",
			                wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)
				return nil
			end
		end
		
		-- Now add the node
		if not nodeInfo.Relative then
			-- This is a root node
			oTree.Roots[#oTree.Roots + 1] = {}
			nodeMeta[oTree.Roots[#oTree.Roots]] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children=0, taskTreeObj = taskTree}
			if oTree.Roots[#oTree.Roots - 1] then
				oTree.Roots[#oTree.Roots].Prev = oTree.Roots[#oTree.Roots - 1]
				oTree.Roots[#oTree.Roots - 1].Next = oTree.Roots[#oTree.Roots]
			end 
			-- Set the nodes meta table to control the node's interface
			setmetatable(oTree.Roots[#oTree.Roots],nodeMeta)
			oTree.Nodes[nodeInfo.Key] = oTree.Roots[#oTree.Roots]
			oTree.nodeCount = oTree.nodeCount + 1
			-- Add it to the GUI here
			if oTree.Nodes[nodeInfo.Key].Prev then
				oTree.Nodes[nodeInfo.Key].Row = oTree.Nodes[nodeInfo.Key].Prev.Row+1
				if oTree.update then
					dispTask(taskTree,oTree.Nodes[nodeInfo.Key].Row,true,oTree.Nodes[nodeInfo.Key],0)
					dispGantt(taskTree,oTree.Nodes[nodeInfo.Key].Row,true,oTree.Nodes[nodeInfo.Key])
					if #oTree.Selected > 0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],0)"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"				
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
				end
			else
				oTree.Nodes[nodeInfo.Key].Row = 1
				if oTree.update then
					dispTask(taskTree,1,true,oTree.Nodes[nodeInfo.Key],0)
					dispGantt(taskTree,1,true,oTree.Nodes[nodeInfo.Key])
					if #oTree.Selected>0 then
						oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
					end
				else
					-- Add to actionQ
					oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,1,true,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."],0)"
					oTree.actionQ[#oTree.actionQ+1] = "dispGantt(tab,1,true,taskTreeINT[tab].Nodes["..
						string.format("%q",nodeInfo.Key).."])"
					oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
				end
			end

			-- return the node
			return oTree.Nodes[nodeInfo.Key]
		else
			-- Add it according to the relation 
			if string.upper(nodeInfo.Relation) == "CHILD" then
				-- Add child
				local parent = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = parent, taskTreeObj = taskTree}
				nodeMeta[parent].Children = nodeMeta[parent].Children + 1 -- increment number of children
				if nodeMeta[parent].FirstChild then
					-- Parent already has children
					nodeMeta[parent].LastChild.Next = newNode
					nodeMeta[newNode].Prev = nodeMeta[parent].LastChild
					nodeMeta[parent].LastChild = newNode
				else
					nodeMeta[parent].FirstChild = newNode
					nodeMeta[parent].LastChild = newNode
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if nodeMeta[parent].Expanded then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					-- Get the row number where this task needs to be placed
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[parent].Key)]
					while true do
						-- Check if nextNode is in the child hierarchy of parent
						local prevNode = parent
						local currNode = nextNode
						local inHier = nil
						while currNode do
							if nodeMeta[currNode].Parent == parent then
								-- In the child hierarchy
								prevNode = nextNode
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
								inHier = true
								break
							end
							currNode = nodeMeta[currNode].Parent
						end
						if not nextNode then
							-- This would be last node in the grid so assign the row one greater than the last visible node
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[prevNode].Row + 1
							break
						end
						if not inHier then
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nextNode].Row
							break
						end
					end
					-- Update the row values of subsequent tasks	
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end

					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
					end
				elseif nodeMeta[parent].Row and nodeMeta[parent].Children == 1 then
					-- This is the 1st child to this visible parent
					-- Add the row label to '+'
					oTree.treeGrid:SetRowLabelValue(nodeMeta[parent].Row-1,"+")
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			elseif string.upper(nodeInfo.Relation) == "NEXT SIBLING" then
				-- Add next sibling
				local sib = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = nodeMeta[sib].Parent, taskTreeObj=taskTree}
				if nodeMeta[sib].Parent then
					nodeMeta[nodeMeta[sib].Parent].Children = nodeMeta[nodeMeta[sib].Parent].Children + 1 -- increment number of children
				else
					oTree.Roots[#oTree.Roots + 1] = newNode
				end
				if nodeMeta[sib].Next then
					-- Node needs to be inserted between these
					nodeMeta[nodeMeta[sib].Next].Prev = newNode
					nodeMeta[newNode].Next = nodeMeta[sib].Next
					nodeMeta[sib].Next = newNode
					nodeMeta[newNode].Prev = sib
				else
					-- Node is the last one
					nodeMeta[sib].Next = newNode
					nodeMeta[newNode].Prev = sib
					if nodeMeta[sib].Parent then
						nodeMeta[nodeMeta[sib].Parent].LastChild = newNode
					end
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if (nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent and 
					nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent].Expanded) or
					not nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					-- Get the row number where this task needs to be placed
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[sib].Key)]
					while true do
						-- Check if nextNode is in the child hierarchy of sib
						local prevNode = sib
						local currNode = nextNode
						local inHier = nil
						while currNode do
							if nodeMeta[currNode].Parent == sib then
								-- In the child hierarchy
								prevNode = nextNode
								nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
								inHier = true
								break
							end
							currNode = nodeMeta[currNode].Parent
						end
						if not nextNode then
							-- This would be last node in the grid so assign the row one greater than the last visible node
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[prevNode].Row + 1
							break
						end
						if not inHier then
							nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nextNode].Row
							break
						end
					end
					-- Update the row values of subsequent tasks	
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end
					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
					end
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			else 
				-- Add previous sibling
				local sib = oTree.Nodes[nodeInfo.Relative]
				local newNode = {}
				nodeMeta[newNode] = {Task = nodeInfo.Task, Title = nodeInfo.Text, Key = nodeInfo.Key, Children = 0, Parent = nodeMeta[sib].Parent, taskTreeObj = taskTree}
				if nodeMeta[sib].Parent then
					nodeMeta[nodeMeta[sib].Parent].Children = nodeMeta[nodeMeta[sib].Parent].Children + 1 -- increment number of children
				else
					oTree.Roots[#oTree.Roots + 1] = newNode
				end
				if nodeMeta[sib].Prev then
					-- Node needs to be inserted between these
					nodeMeta[nodeMeta[sib].Prev].Next = newNode
					nodeMeta[newNode].Prev = nodeMeta[sib].Prev
					nodeMeta[sib].Prev = newNode
					nodeMeta[newNode].Next = sib
				else
					-- Node is the First one
					nodeMeta[sib].Prev = newNode
					nodeMeta[newNode].Next = sib
					if nodeMeta[sib].Parent then
						nodeMeta[nodeMeta[sib].Parent].FirstChild = newNode
					end
				end
				-- Set the metatable
				setmetatable(newNode,nodeMeta) 
				oTree.Nodes[nodeInfo.Key] = newNode
				oTree.nodeCount = oTree.nodeCount + 1
				-- Add it to the GUI here
				if (nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent and 
					nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent].Expanded) or
					not nodeMeta[oTree.Nodes[nodeInfo.Key]].Parent then
					-- This child needs to be displayed
					local hierLevel = 0
					local currNode = oTree.Nodes[nodeInfo.Key]
					while nodeMeta[currNode].Parent do
						hierLevel = hierLevel + 1
						currNode = nodeMeta[currNode].Parent
					end
					nodeMeta[oTree.Nodes[nodeInfo.Key]].Row = nodeMeta[nodeMeta[oTree.Nodes[nodeInfo.Key]].Next].Row
					-- Update the row values of subsequent tasks	
					local nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Key)]
					while nextNode do
						nextNode.Row = nextNode.Row + 1
						nextNode = oTree.Nodes[taskTreeINT.nextVisibleNode(taskTree,nodeMeta[nextNode].Key)]
					end
					if oTree.update then
						dispTask(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key],hierLevel)
						dispGantt(taskTree,nodeMeta[oTree.Nodes[nodeInfo.Key]].Row,true,oTree.Nodes[nodeInfo.Key])
						if #oTree.Selected>0 then
							oTree.treeGrid:SetGridCursor(oTree.Selected[oTree.Selected.Latest].Row-1,1)
						end
					else
						-- Add to actionQ
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."],"..tostring(hierLevel)..")"
						oTree.actionQ[#oTree.actionQ+1] = "dispTask(tab,taskTreeINT[tab].Nodes["..
							string.format("%q",nodeInfo.Key).."].Row,true,taskTreeINT[tab].Nodes["..string.format("%q",nodeInfo.Key).."])"
						oTree.actionQ[#oTree.actionQ+1] = "if #taskTreeINT[tab].Selected>0 then taskTreeINT[tab].treeGrid:SetGridCursor(taskTreeINT[tab].Selected[taskTreeINT[tab].Selected.Latest].Row-1,1) end"
					end
				end			
				-- return the node
				return oTree.Nodes[nodeInfo.Key]
			end
		end		-- if not nodeInfo.Relative then ends here
	end		-- function taskTreeINT.AddNode ends here
	
	local function labelClickFunc(event)
		-- Find the row of the click
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		if row>-1 then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			-- Check if the taskNode has children
			if nodeMeta[taskNode].Children > 0 then
				if nodeMeta[taskNode].Expanded then
					taskNode.Expanded = nil
				else
					taskNode.Expanded = true
				end
			end
		end		
		if taskTreeINT[obj].rowLabelClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].rowLabelClickCallBack(taskNode.Task, row, -1)
		end
		--event:Skip()
	end
	
	local function ganttLabelClickFunc(event)
		-- Find the row of the click
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		local col = event:GetCol()
		if taskTreeINT[obj].Planning then
			local oTree = taskTreeINT[obj]
			if row > -1 then
				for i = 1,#oTree.taskList do
					if oTree.Nodes[oTree.taskList[i].TaskID].Row == row+1 then
						-- This is the task modify/add the planning schedule
						Karm.TaskObject.togglePlanningType(oTree.taskList[i],oTree.Planning)
						dispGanttFunc(obj,row+1,false,oTree.Nodes[oTree.taskList[i].TaskID])
						break
					end
				end
			end		-- if row > -1 then ends
		end		-- if taskTreeINT[obj].Planning then ends
		if taskTreeINT[obj].ganttRowLabelClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].ganttRowLabelClickCallBack(taskNode.Task, row, -1)
		end
		--event:Skip()
	end

	local function postOnScrollTree(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			oTree.ganttGrid:Scroll(oTree.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.treeGrid:GetScrollPos(wx.wxVERTICAL))
		end
	end

	local function onScrollTreeFunc(obj)
		return function(event)
			local ID = wx.wxID_ANY
			local evt = wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, ID)
			local oTree = taskTreeINT[obj]
			oTree.treeGrid:Connect(ID,wx.wxEVT_COMMAND_BUTTON_CLICKED,postOnScrollTree(obj))
			oTree.treeGrid:AddPendingEvent(evt)
			event:Skip()
		end
	end
	onScrollTree = onScrollTreeFunc
	
	local function onRowResizeGanttFunc(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			local row = event:GetRowOrCol()
			oTree.treeGrid:SetRowSize(row,oTree.ganttGrid:GetRowSize(row))
			oTree.treeGrid:ForceRefresh()
			event:Skip()
		end
	end
	
	onRowResizeGantt = onRowResizeGanttFunc
	
	local function onRowResizeTreeFunc(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			local row = event:GetRowOrCol()
			oTree.ganttGrid:SetRowSize(row,oTree.treeGrid:GetRowSize(row))
			oTree.ganttGrid:ForceRefresh()
			event:Skip()
		end	
	end
	
	onRowResizeTree = onRowResizeTreeFunc
	
	local function postOnScrollGantt(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			oTree.treeGrid:Scroll(oTree.treeGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.ganttGrid:GetScrollPos(wx.wxVERTICAL))

			local currDate = oTree.startDate
			local finDate = oTree.finDate
			local count = 0
--			local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count))
--			y1 = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count+1),wx.wxGridCellCoords(0,count+1))
--   			Karm.GUI.frame:SetStatusText(tostring(y:GetTopLeft():GetX())..","..tostring(y:GetTopLeft():GetY())..","..
--   			  tostring(y1:GetTopLeft():GetX())..","..tostring(y1:GetTopLeft():GetY()), 1)
   			
    		--local x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
    		--local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
    		local x = oTree.ganttGrid:IsVisible(0,count, false)
			while not x and not currDate:IsLaterThan(finDate) do
				count = count + 1
				currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
				x = oTree.ganttGrid:IsVisible(0,count, false)
				--x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
			end

			-- Now currDate has the date that is not fully visible
			-- Check if the column is more than 60% visible
    		local p6w = oTree.ganttGrid:GetColSize(count)
    		p6w = 0.6*p6w
    		p6w = p6w - p6w%1
    		x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopRight():GetX()
    		if x < p6w then
    			count = count + 1
    			currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
    		end

			local corner = oTree.ganttGrid:GetGridCornerLabelWindow()
			corner:DestroyChildren()
			-- Add the Month and year in the corner
			local sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local textLabel = wx.wxStaticText(corner, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)
			textLabel:SetLabel(currDate:Format("%b %Y"))
			sizer:Add(textLabel, 1, wx.wxLEFT+wx.wxRIGHT+wx.wxALIGN_CENTRE_VERTICAL, 3)
			corner:SetSizer(sizer)
			corner:Layout()	
			oTree.startDate = oTree.startDate:Subtract(wx.wxDateSpan(0,0,0,count))					
		end
	end
	
	local function onScrollGanttFunc(obj)
		return function(event)
			local ID = wx.wxID_ANY
			local evt = wx.wxCommandEvent(wx.wxEVT_COMMAND_BUTTON_CLICKED, ID)
			local oTree = taskTreeINT[obj]
			oTree.ganttGrid:Connect(ID,wx.wxEVT_COMMAND_BUTTON_CLICKED,postOnScrollGantt(obj))
			oTree.ganttGrid:AddPendingEvent(evt)
			event:Skip()
		end
	end
	onScrollGantt = onScrollGanttFunc
	
	
	local function horSashAdjustFunc(event)
		--local info = "Sash: "..tostring(Karm.GUI.horSplitWin:GetSashPosition()).."\nCol 0: "..tostring(Karm.GUI.treeGrid:GetColSize(0)).."\nCol 1 Before: "..tostring(Karm.GUI.treeGrid:GetColSize(1))
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		oTree.treeGrid:SetColMinimalWidth(1,oTree.horSplitWin:GetSashPosition()-oTree.treeGrid:GetColSize(0)-oTree.treeGrid:GetRowLabelSize(0))
		oTree.treeGrid:AutoSizeColumn(1,false)
		--info = info.."\nCol 1 After: "..tostring(Karm.GUI.treeGrid:GetColSize(1))
		--Karm.GUI.taskDetails:SetValue(info)	
		event:Skip()
	end
	
	local function widgetResizeFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local winSize = event:GetSize()
		local wid = 0.3*winSize:GetWidth()
		if wid > 400 then
			wid = 400
		end
		oTree.horSplitWin:SetSashPosition(wid)
		oTree.treeGrid:SetColMinimalWidth(1,oTree.horSplitWin:GetSashPosition()-oTree.treeGrid:GetColSize(0)-oTree.treeGrid:GetRowLabelSize(0))
		oTree.treeGrid:AutoSizeColumn(1,false)
		event:Skip()
	end
	
	local function cellClickFunc(event)
		local obj = IDMap[event:GetId()]
		local row = event:GetRow()
		local col = event:GetCol()
		if row>-1 then
			if col == 1 then
				local taskNode
				-- Find the task associated with the row
				for i,v in taskTreeINT.tpairs(obj) do
					v.Selected = false	-- Make everything else unselected
					if v.Row == row+1 then
						taskNode = v
					end
				end		-- Looping through all the nodes ends
				-- print("Clicked row "..tostring(row))
				taskNode.Selected = true
				taskTreeINT[obj].Selected = {taskNode,Latest=1}
				if taskTreeINT[obj].cellClickCallBack then
					taskTreeINT[obj].cellClickCallBack(taskNode.Task, row, col)
				end
			else
				taskTreeINT[obj].Selected = {}
			end
			taskTreeINT[obj].treeGrid:SetGridCursor(row,col)
		end		
		--taskTreeINT[obj].treeGrid:SelectBlock(row,col,row,col)
		--event:Skip()
	end
	
	local function ganttCellDblClickFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local row = event:GetRow()
		local col = event:GetCol()
		-- Find the date on which clicked
		local colCount = 0					
		local stepDate = Karm.Utility.XMLDate2wxDateTime(Karm.Utility.toXMLDate(taskTreeINT[obj].startDate:Format("%m/%d/%Y")))
		while colCount < col do
			stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
			colCount = colCount + 1
		end
		if oTree.ganttCellDblClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			oTree.ganttCellDblClickCallBack(taskNode.Task, row, col, Karm.Utility.toXMLDate(stepDate:Format("%m/%d/%Y")))
		end
	end
	
	local function ganttCellClickFunc(event)
		local obj = IDMap[event:GetId()]
		local oTree = taskTreeINT[obj]
		local row = event:GetRow()
		local col = event:GetCol()
		local colCount = 0					
		local stepDate = Karm.Utility.XMLDate2wxDateTime(Karm.Utility.toXMLDate(taskTreeINT[obj].startDate:Format("%m/%d/%Y")))
		while colCount < col do
			stepDate = stepDate:Add(wx.wxDateSpan(0,0,0,1))
			colCount = colCount + 1
		end
		if taskTreeINT[obj].Planning then
			if row > -1 then
				for i = 1,#oTree.taskList do
					if oTree.Nodes[oTree.taskList[i].TaskID].Row == row+1 then
						-- This is the task modify/add the planning schedule
						Karm.TaskObject.togglePlanningDate(oTree.taskList[i],Karm.Utility.toXMLDate(stepDate:Format("%m/%d/%Y")),oTree.Planning)
						dispGanttFunc(obj,row+1,false,oTree.Nodes[oTree.taskList[i].TaskID])
						break
					end
				end
			end		-- if row > -1 then ends
		end		-- if taskTreeINT[obj].Planning then ends
		oTree.ganttGrid:SetGridCursor(event:GetRow(),event:GetCol())
		if taskTreeINT[obj].ganttCellClickCallBack then
			local taskNode
			-- Find the task associated with the row
			for i,v in taskTreeINT.tvpairs(obj) do
				if v.Row == row+1 then
					taskNode = v
					break
				end
			end		-- Looping through all the nodes ends
			taskTreeINT[obj].ganttCellClickCallBack(taskNode.Task, row, col, Karm.Utility.toXMLDate(stepDate:Format("%m/%d/%Y")))
		end
		cellClickFunc(wx.wxGridEvent(event:GetId(),wx.wxEVT_GRID_CELL_LEFT_CLICK,oTree.treeGrid,event:GetRow(),1))
	end		-- local function ganttCellClickFunc(event) ends
	
	ganttCellClick = ganttCellClickFunc
	ganttCellDblClick = ganttCellDblClickFunc
	ganttLabelClick = ganttLabelClickFunc
	cellClick = cellClickFunc
	widgetResize = widgetResizeFunc
	horSashAdjust = horSashAdjustFunc
	labelClick = labelClickFunc
	
end	-- The custom tree and Gantt widget object for Karm ends here

-- Function to generate and return the node color of a TaskTree node
function Karm.GUI.getNodeColor(node)
	-- Get the node colors according to the status
	if not node.Task then
		return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
	else
		if Karm.Globals.StatusNodeColor then
			for i = 1,#Karm.Globals.StatusList do
				if node.Task.Status == Karm.Globals.StatusList[i] and Karm.Globals.StatusNodeColor[i] then
					local foreColor = Karm.GUI.nodeForeColor
					local backColor = Karm.GUI.nodeBackColor
					if Karm.Globals.StatusNodeColor[i].ForeColor and Karm.Globals.StatusNodeColor[i].ForeColor.Red and 
					  Karm.Globals.StatusNodeColor[i].ForeColor.Blue and Karm.Globals.StatusNodeColor[i].ForeColor.Green then
						foreColor = Karm.Globals.StatusNodeColor[i].ForeColor
					end
					if Karm.Globals.StatusNodeColor[i].BackColor and Karm.Globals.StatusNodeColor[i].BackColor.Red and 
					  Karm.Globals.StatusNodeColor[i].BackColor.Blue and Karm.Globals.StatusNodeColor[i].BackColor.Green then
						backColor = Karm.Globals.StatusNodeColor[i].BackColor
					end
					return foreColor, backColor
				end
			end
			return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
		else
			return Karm.GUI.nodeForeColor, Karm.GUI.nodeBackColor
		end	
	end
end

function Karm.GUI.addTask(task)
	local parent = task.Parent
	while parent do
		if Karm.GUI.taskTree.Nodes[parent.TaskID] then
			-- Put the task under this node
			local currNode = Karm.GUI.taskTree:AddNode{Relative=parent.TaskID, Relation="Child", Key=task.TaskID, Text=task.Title, Task=task}
			currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
			return true
		end
	end
	-- No hierarchy was found so this has to be the root node in a spore
	if not Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..task.SporeFile] then
		-- Spore also does not exist
		Karm.GUI.addSpore(task.SporeFile, Karm.SporeData[task.SporeFile])
		return true
	end
	local currNode = Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY..task.SporeFile, Relation="Child", Key=task.TaskID, Text=task.Title, Task=task}
	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
	return true	
end

function Karm.GUI.addSpore(key,Spore)
	-- Add the spore node
	Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY, Relation="Child", Key=Karm.Globals.ROOTKEY..key, Text=Spore.Title, Task = Spore}
	Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key].ForeColor,Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..key])
	local taskList = Karm.FilterObject.applyFilterHier(Karm.Filter, Spore)
	-- Now add the tasks under the spore in the TaskTree
	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore
	    -- Add the 1st element under the spore
	    local currNode = Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY..key, Relation="Child", Key=taskList[1].TaskID, 
	    		Text=taskList[1].Title, Task=taskList[1]}
		currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
	    for intVar = 2,taskList.count do
	    	local cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..key
	    	local cond2 = #taskList[intVar].TaskID > #currNode.Key
	    	local cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
	    	while cond1 and not (cond2 and cond3) do
	        	-- Go up the hierarchy
	        	currNode = currNode.Parent
	        	cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..key
	        	cond2 = #taskList[intVar].TaskID > #currNode.Key
	        	cond3 = string.sub(taskList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
	        end
	    	-- Now currNode has the node which is the right parent
	        currNode = Karm.GUI.taskTree:AddNode{Relative=currNode.Key, Relation="Child", Key=taskList[intVar].TaskID, 
	        		Text=taskList[intVar].Title, Task = taskList[intVar]}
	    	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
	    end
	end  -- if taskList.count > 0 then ends
end

--****f* Karm/Karm.GUI.fillTaskTree
-- FUNCTION
-- Function to recreate the task tree based on the global filter criteria from all the loaded spores
--
-- SOURCE
function Karm.GUI.fillTaskTree()
-- ALGORITHM

	local prevSelect, restorePrev
	local expandedStatus = {}
	Karm.GUI.taskTree.update = false		-- stop GUI updates for the time being    
    if Karm.GUI.taskTree.nodeCount > 0 then
-- Check if the task Tree has elements then get the current selected nodekey this will be selected again after the tree view is refreshed
        for i,v in Karm.GUI.taskTree.tpairs(Karm.GUI.taskTree) do
        	if v.Expanded then
        		-- NOTE: i is the same as the TaskID i.e. i == Karm.GUI.taskTree.Nodes[i].Task.TaskID
            	expandedStatus[i] = true
            end
            if v.Selected then
                prevSelect = i
            end
        end
        restorePrev = true
    end
    
-- Clear the treeview and add the root element
    Karm.GUI.taskTree:Clear()
    Karm.GUI.taskTree:AddNode{Key=Karm.Globals.ROOTKEY, Text = "Task Spores"}
    Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].ForeColor, Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY])

    if Karm.SporeData[0] > 0 then
-- Populate the tree control view
        for k,v in pairs(Karm.SporeData) do
        	if k~=0 then
            -- Get the tasks in the spore
-- Add the spore to the TaskTree
				Karm.GUI.addSpore(k,v)
			end		-- if k~=0 then ends
-- Repeat for all spores
        end		-- for k,v in pairs(Karm.SporeData) do ends
    end  -- if Karm.SporeData[0] > 0 then ends
    local selected
    if restorePrev then
-- Update the tree status to before the refresh
        for k,currNode in Karm.GUI.taskTree.tpairs(Karm.GUI.taskTree) do
            if expandedStatus[currNode.Key] then
                currNode.Expanded = true
			end
        end
        for k,currNode in Karm.GUI.taskTree.tvpairs(Karm.GUI.taskTree) do
            if currNode.Key == prevSelect then
                currNode.Selected = true
                selected = currNode.Task
            end
        end
    else
 		Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY].Expanded = true
    end
	Karm.GUI.taskTree.update = true		-- Resume the tasktree update    
	-- Update the Filter summary
	if Karm.Filter then
		Karm.GUI.taskFilter:SetValue(Karm.FilterObject.getSummary(Karm.Filter))
	else
	    Karm.GUI.taskFilter:SetValue("No Filter")
	end
    Karm.GUI.taskDetails:SetValue(Karm.TaskObject.getSummary(selected))
end
--@@END@@

function Karm.GUI.frameResize(event)
	local winSize = event:GetSize()
	local hei = 0.6*winSize:GetHeight()
	if winSize:GetHeight() - hei > 400 then
		hei = winSize:GetHeight() - 400
	end
	Karm.GUI.vertSplitWin:SetSashPosition(hei)
	event:Skip()
end

function Karm.GUI.dateRangeChangeEvent(event)
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local finDate = Karm.GUI.dateFinPick:GetValue()
	Karm.GUI.taskTree:dateRangeChange(startDate,finDate)
	event:Skip()
end

function Karm.GUI.dateRangeChange()
	-- Clear the GanttGrid
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local finDate = Karm.GUI.dateFinPick:GetValue()
	Karm.GUI.taskTree:dateRangeChange(startDate,finDate)
end

function Karm.createNewSpore(title, relation, relative)
	local SporeName
	if title then
		SporeName = title
	else
		SporeName = wx.wxGetTextFromUser("Enter the New Spore File name under which to move the task (Blank to cancel):", "New Spore", "")
	end
	if SporeName == "" then
		return
	end
	relation = relation or "Child"
	relative = relative or Karm.Globals.ROOTKEY
	Karm.SporeData[SporeName] = Karm.XML2Data({[0]="Task_Spore"}, SporeName)
	Karm.SporeData[SporeName].Modified = "YES"
	Karm.SporeData[0] = Karm.SporeData[0] + 1
	Karm.GUI.taskTree:AddNode{Relative=relative, Relation=relation, Key=Karm.Globals.ROOTKEY..SporeName, Text=SporeName, Task = Karm.SporeData[SporeName]}
	Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].ForeColor, Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName])
	Karm.Globals.unsavedSpores[SporeName] = Karm.SporeData[SporeName].Title
	return Karm.Globals.ROOTKEY..SporeName
end

-- For MoveTask it needs the following information
--	Karm.GUI.MoveTask.action = ID
--	Karm.GUI.MoveTask.task = taskList[1].Task
-- For CopyTask it needs the following information
--	Karm.GUI.CopyTask.action = ID
--	Karm.GUI.CopyTask.task = taskList[1].Task
function Karm.moveCopyTask(task)
	-- Do the move/copy task here
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
		-- Cancel the move/copy
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.MoveTask = nil
		Karm.GUI.CopyTask = nil
		Karm.GUI.ResetMoveTools()
		Karm.GUI.ResetCopyTools()
        return
	end			
	if #taskList > 1 then
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.MoveTask = nil
		Karm.GUI.CopyTask = nil
		-- Cancel the move/copy
		Karm.GUI.ResetMoveTools()
		Karm.GUI.ResetCopyTools()
        return
	end		
	if Karm.GUI.MoveTask and taskList[1].Task ~= Karm.GUI.MoveTask.task or Karm.GUI.CopyTask and taskList[1].Task ~= Karm.GUI.CopyTask.task then
		-- Start the move/copy
		if taskList[1].Key == Karm.Globals.ROOTKEY then
			-- Relative is the Root node
			if Karm.GUI.MoveTask and (Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_ABOVE or Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_BELOW) then
				wx.wxMessageBox("Can only move a task under the root task!","Illegal Move", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
			if Karm.GUI.CopyTask and (Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_ABOVE or Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_BELOW) then
				wx.wxMessageBox("Can only copy a task under the root task!","Illegal Copy", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
			-- This is to move/copy the task into a new Spore
			-- Create a new Spore here and make that the target parent instead of the root node
			taskList[1] = Karm.GUI.taskTree.Nodes[Karm.createNewSpore()]
		end
		local task, str 
		if Karm.GUI.MoveTask then
			task = Karm.GUI.MoveTask.task
			str = "Move"
		else
			-- Make a copy of the task and all its sub tasks and remove any DBDATA from the task to make a new task
			task = Karm.TaskObject.copy(Karm.GUI.CopyTask.task, true, true)
			str = "Copy"
		end
		if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- Relative is Spore
			if (Karm.GUI.MoveTask and (Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_ABOVE or Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_BELOW))
			  or (Karm.GUI.CopyTask and (Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_ABOVE or Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_BELOW)) then
				-- Create a new spore and move/copy it under there (set that the new target parent)
				taskList[1] = Karm.GUI.taskTree.Nodes[Karm.createNewSpore()]
			end
			-- This is to move/copy the task into this spore
			local taskID
			-- Get a new task ID
			taskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", str.." Task Under Spore", "")
			if taskID == "" then
				-- Cancel the move/copy
				Karm.GUI.statusBar:SetStatusText("",0)
				Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
				Karm.GUI.MoveTask = nil
				Karm.GUI.CopyTask = nil
				return
			end
			-- Check if the task ID exists in all the loaded spores
			while true do
				local redo = nil
				for k,v in pairs(Karm.SporeData) do
        			if k~=0 then
						local list = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=taskID}}}, v)
						if #list > 0 then
							redo = true
							break
						end
					end
				end
				if redo then
					taskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", str.." Task Under Spore", "")
					if taskID == "" then
						-- Cancel the move/copy
						Karm.GUI.statusBar:SetStatusText("",0)
						Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
						Karm.GUI.MoveTask = nil
						Karm.GUI.CopyTask = nil
						return
					end
				else
					break
				end
			end		
			
			if Karm.GUI.MoveTask then	
				-- Delete it from db
				-- Delete from Spores
				-- Parent of a root node is nil
				Karm.TaskObject.DeleteFromDB(task)
				-- Delete from task Tree GUI
				Karm.GUI.taskTree:DeleteTree(task.TaskID)
			end
			Karm.TaskObject.updateTaskID(task,taskID)
			task.Parent = nil
			task.SporeFile = string.sub(taskList[1].Key,#Karm.Globals.ROOTKEY+1,-1)
			Karm.GUI.TaskWindowOpen = {Spore = true, Relative = taskList[1].Key, Relation = "Child"}
			Karm.NewTaskCallBack(task)		-- This takes care of adding the task to the database and also displaying this task		
			if task.SubTasks then
				-- Update the SubTasks parent
				--task.SubTasks.parent = Karm.SporeData[task.SporeFile]  DONE IN ADD2SPORE
				-- Update the Spore file in all sub tasks
				local list1 = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[task.SporeFile])
				if #list1 > 0 then
					for i = 1,#list1 do
						list1[i].SporeFile = task.SporeFile
					end
				end					
				-- Now add all the Child hierarchy of the moved task to the GUI
				local addList = Karm.FilterObject.applyFilterHier(Karm.Filter, task.SubTasks)
				-- Now add the tasks under the spore in the TaskTree
            	if addList.count > 0 then  --There are some tasks passing the criteria in this spore
    	            local currNode = Karm.GUI.taskTree.Nodes[task.TaskID]
	                for intVar = 1,addList.count do
	                	local cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..task.SporeFile
	                	local cond2 = #addList[intVar].TaskID > #currNode.Key
	                	local cond3 = string.sub(addList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                    	while cond1 and not (cond2 and cond3) do
                        	-- Go up the hierarchy
                        	currNode = currNode.Parent
		                	cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..task.SporeFile
		                	cond2 = #addList[intVar].TaskID > #currNode.Key
		                	cond3 = string.sub(addList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                        end
                    	-- Now currNode has the node which is the right parent
	                    currNode = Karm.GUI.taskTree:AddNode{Relative=currNode.Key, Relation="Child", Key=addList[intVar].TaskID, 
	                    		Text=addList[intVar].Title, Task = addList[intVar]}
                    	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
                    end
	            end  -- if addList.count > 0 then ends
			end		-- if task.SubTasks then ends
		else		-- if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- This is to move/copy the task in relation to this task
			-- This relative might be a Spore root task or a normal hierarchy task
			if Karm.GUI.MoveTask and Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_UNDER or Karm.GUI.CopyTask and Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_UNDER then
				-- Sub task handling is same in both cases
				if Karm.GUI.MoveTask then
					-- Delete it from db
					-- Delete from Spores
					Karm.TaskObject.DeleteFromDB(task)
					-- Delete from task Tree GUI
					Karm.GUI.taskTree:DeleteTree(task.TaskID)
				end
				Karm.TaskObject.updateTaskID(task, Karm.TaskObject.getNewChildTaskID(taskList[1].Task))
				task.Parent = taskList[1].Task
				Karm.GUI.TaskWindowOpen = {Relative = taskList[1].Key, Relation = "Child"}
			else		-- if Karm.GUI.MoveTask and Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_UNDER or Karm.GUI.CopyTask and Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_UNDER then else
				local parent, taskID
				if not taskList[1].Task.Parent then
					-- This is a spore root node so will have to ask for the task ID from the user
					taskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", str.." Task", "")
					if taskID == "" then
						-- Cancel the move
						Karm.GUI.statusBar:SetStatusText("",0)
						Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
						Karm.GUI.MoveTask = nil
						Karm.GUI.CopyTask = nil
						return
					end
					-- Check if the task ID exists in all the loaded spores
					while true do
						local redo = nil
						for k,v in pairs(Karm.SporeData) do
		        			if k~=0 then
								local list = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=taskID}}}, v)
								if #list > 0 then
									redo = true
									break
								end
							end
						end
						if redo then
							taskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", str.." Task", "")
							if taskID == "" then
								-- Cancel the move
								Karm.GUI.statusBar:SetStatusText("",0)
								Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
								Karm.GUI.MoveTask = nil
								Karm.GUI.CopyTask = nil
								return
							end
						else
							break
						end
					end		
					-- Parent of a root node is nil	
				else				
					taskID = Karm.TaskObject.getNewChildTaskID(taskList[1].Task.Parent)
					parent = taskList[1].Task.Parent
				end		-- if not taskList[1].Task.Parent then ends
				if Karm.GUI.MoveTask and Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_ABOVE or Karm.GUI.CopyTask and Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_ABOVE then
					-- Move/Copy Above
					Karm.GUI.TaskWindowOpen = {Relative = taskList[1].Key, Relation = "PREV SIBLING"}
				else
					-- Move?Copy Below
					Karm.GUI.TaskWindowOpen = {Relative = taskList[1].Key, Relation = "NEXT SIBLING"}
				end
				if Karm.GUI.MoveTask then
					-- Delete it from db
					-- Delete from Spores
					Karm.TaskObject.DeleteFromDB(task)
					-- Delete from task Tree Karm.GUI
					Karm.GUI.taskTree:DeleteTree(task.TaskID)
				end
				Karm.TaskObject.updateTaskID(task,taskID)
				task.Parent = parent
			end		-- if Karm.GUI.MoveTask and Karm.GUI.MoveTask.action == Karm.GUI.ID_MOVE_UNDER or Karm.GUI.CopyTask and Karm.GUI.CopyTask.action == Karm.GUI.ID_COPY_UNDER then ends				
			task.SporeFile = taskList[1].Task.SporeFile
			Karm.NewTaskCallBack(task)		-- This takes care of adding the task to the database and also displaying this task
			if task.SubTasks then
				-- update the SubTasks parent
				--task.SubTasks.parent = taskList[1].Task.SubTasks  DONE IN ADD2PARENT
				-- Update the Spore file in all sub tasks
				local list1 = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[task.SporeFile])
				if #list1 > 0 then
					for i = 1,#list1 do
						list1[i].SporeFile = task.SporeFile
					end
				end										
				-- Now add all the Child hierarchy of the moved task to the GUI
				local addList = Karm.FilterObject.applyFilterHier(Karm.Filter, task.SubTasks)
				-- Now add the tasks under the spore in the TaskTree
            	if addList.count > 0 then  --There are some tasks passing the criteria in this spore
    	            local currNode = Karm.GUI.taskTree.Nodes[task.TaskID]
	                for intVar = 1,addList.count do
	                	local cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..task.SporeFile
	                	local cond2 = #addList[intVar].TaskID > #currNode.Key
	                	local cond3 = string.sub(addList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                    	while cond1 and not (cond2 and cond3) do
                        	-- Go up the hierarchy
                        	currNode = currNode.Parent
		                	cond1 = currNode.Key ~= Karm.Globals.ROOTKEY..task.SporeFile
		                	cond2 = #addList[intVar].TaskID > #currNode.Key
		                	cond3 = string.sub(addList[intVar].TaskID, 1, #currNode.Key + 1) == currNode.Key.."_"
                        end
                    	-- Now currNode has the node which is the right parent
	                    currNode = Karm.GUI.taskTree:AddNode{Relative=currNode.Key, Relation="Child", Key=addList[intVar].TaskID, 
	                    		Text=addList[intVar].Title, Task = addList[intVar]}
                    	currNode.ForeColor, currNode.BackColor = Karm.GUI.getNodeColor(currNode)
                    end
	            end  -- if addList.count > 0 then ends
			end		-- if task.SubTasks then ends
		end		-- if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then ends
		Karm.Globals.unsavedSpores[taskList[1].Task.SporeFile] = Karm.SporeData[taskList[1].Task.SporeFile].Title
		if Karm.GUI.MoveTask then
			Karm.Globals.unsavedSpores[Karm.GUI.MoveTask.task.SporeFile] = Karm.SporeData[Karm.GUI.MoveTask.task.SporeFile].Title
		else
			Karm.Globals.unsavedSpores[Karm.GUI.CopyTask.task.SporeFile] = Karm.SporeData[Karm.GUI.CopyTask.task.SporeFile].Title
		end
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.MoveTask = nil
		Karm.GUI.CopyTask = nil
		-- Finish the move
		Karm.GUI.ResetMoveTools()
		Karm.GUI.ResetCopyTools()
	end		-- if Karm.GUI.MoveTask and taskList[1].Task ~= Karm.GUI.MoveTask.task or Karm.GUI.CopyTask and taskList[1].Task ~= Karm.GUI.CopyTask.task then ends
end		-- function Karm.moveCopyTask ends

function Karm.GUI.taskClicked(task)
	Karm.GUI.taskDetails:SetValue(Karm.TaskObject.getSummary(task))
	if Karm.GUI.MoveTask or Karm.GUI.CopyTask then
		Karm.moveCopyTask(task)
	end		-- if Karm.GUI.MoveTask then ends here
end		-- function taskClicked(task) ends here

function Karm.LoadFilter(file)
	local safeenv = {}
	setmetatable(safeenv, {__index = Karm.Globals.safeenv})
	local f,message = loadfile(file)
	if not f then
		return nil,message
	end
	setfenv(f,safeenv)
	f()
	if safeenv.filter and type(safeenv.filter) == "table" then
		if safeenv.filter.Script then
			f, message = loadstring(safeenv.filter.Script)
			if not f then
				return nil,"Cannot compile custom script in filter. Error: "..message
			end
		end
		return safeenv.filter
	else
		return nil,"Cannot find a valid filter in the file."
	end
end

function Karm.SetFilterCallBack(filter)
	Karm.GUI.FilterWindowOpen = false
	if filter then
		Karm.Filter = filter
		Karm.GUI.fillTaskTree()
	end
end

function Karm.SetFilter(event)
	if not Karm.GUI.FilterWindowOpen then
		Karm.GUI.FilterForm.filterFormActivate(Karm.GUI.frame,Karm.SetFilterCallBack)
		Karm.GUI.FilterWindowOpen = true
	else
		Karm.GUI.FilterForm.frame:SetFocus()
	end
end

-- Relative = relative of this new node (should be a task ID) 
-- Relation = relation of this new node to the Relative. This can be "Child", "Next Sibling", "Prev Sibling" 
function Karm.NewTaskCallBack(task)
	if task then
		if AutoFillTask then
			AutoFillTask(task)
		end
		if Karm.GUI.TaskWindowOpen.Spore then
			-- Add child to Spore i.e. Create a new root task in the spore
			-- Add the task to the Karm.SporeData
			Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
		else
			-- Normal Hierarchy add
			if Karm.GUI.TaskWindowOpen.Relation:upper() == "CHILD" then
				-- Add child
				Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
			elseif Karm.GUI.TaskWindowOpen.Relation:upper() == "NEXT SIBLING" then
				-- Add as next sibling
				if not task.Parent then
					-- Task is a root task in a spore
					Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"AFTER",Karm.SporeData[task.SporeFile])
				else
					-- First add as child
					Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"AFTER")
					-- Now modify the GUI keys
					local currNode = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Parent.LastChild
					local relative = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative]
					while currNode ~= relative do
						Karm.GUI.taskTree:UpdateKeys(currNode)
						currNode = currNode.Prev					
					end
				end		-- if not task.Parent then ends here
			else
				-- Add as previous sibling
				if not task.Parent then
					-- Task is a root spore node
					Karm.TaskObject.add2Spore(task,Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"BEFORE",Karm.SporeData[task.SporeFile])
				else
					-- First add as child
					Karm.TaskObject.add2Parent(task, task.Parent, Karm.SporeData[task.SporeFile])
					-- Now move it to the right place
					Karm.TaskObject.bubbleTask(task,Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Task,"BEFORE")
					-- Now modify the Karm.GUI keys and add it to the UI
					local currNode = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative].Parent.LastChild
					local relative = Karm.GUI.taskTree.Nodes[Karm.GUI.TaskWindowOpen.Relative]
					while currNode ~= relative do
						Karm.GUI.taskTree:UpdateKeys(currNode)
						currNode = currNode.Prev					
					end
					-- Move the relative also
					Karm.GUI.taskTree:UpdateKeys(currNode)
					-- Since the Relative ID has changed update the ID in TaskWindowOpen here
					Karm.GUI.TaskWindowOpen.Relative = currNode.Key
				end		-- if not task.Parent then ends here
			end		-- if Karm.GUI.TaskWindowOpen.Relation:upper() == "CHILD" then ends here
		end		-- if Karm.GUI.TaskWindowOpen.Spore then ends here
		local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
		if #taskList == 1 then
		    Karm.GUI.taskTree:AddNode{Relative=Karm.GUI.TaskWindowOpen.Relative, Relation=Karm.GUI.TaskWindowOpen.Relation, Key=task.TaskID, Text=task.Title, Task=task}
	    	Karm.GUI.taskTree.Nodes[task.TaskID].ForeColor, Karm.GUI.taskTree.Nodes[task.TaskID].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[task.TaskID])
	    end
		Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
    end		-- if task then ends
	Karm.GUI.TaskWindowOpen = false
end

function Karm.EditTaskCallBack(task)
	if task then
		-- Replace task into Karm.GUI.TaskWindowOpen.Task
		if not Karm.GUI.TaskWindowOpen.Task.Parent then
			-- This is a root task in the Spore
			local Spore = Karm.SporeData[Karm.GUI.TaskWindowOpen.Task.SporeFile]
			for i=1,#Spore do
				if Spore[i] == Karm.GUI.TaskWindowOpen.Task then
					Spore[i] = task
					break
				end
			end
		else
			local parentTask = Karm.GUI.TaskWindowOpen.Task.Parent
			for i=1,#parentTask.SubTasks do
				if parentTask.SubTasks[i] == Karm.GUI.TaskWindowOpen.Task then
					parentTask.SubTasks[i] = task
					-- The task already has correct links to its neighbors and parent
					-- We just need to update the neighbor links to the task to completely delink the previous task table.
					if task.Previous then
						task.Previous.Next = task
					end
					if task.Next then
						task.Next.Previous = task
					end
					break
				end
			end
		end
		-- Update the task in the Karm.GUI here
		-- Check if the task passes the filter now
		local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
		if #taskList == 1 then
			-- It passes the filter so update the task
		    Karm.GUI.taskTree:UpdateNode(task)
			Karm.GUI.taskTree.Nodes[task.TaskID].ForeColor, Karm.GUI.taskTree.Nodes[task.TaskID].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[task.TaskID])
			Karm.GUI.taskClicked(task)
	    else
	    	-- Delete the task node and adjust the hier level of all the sub task hierarchy if any
	    	Karm.GUI.taskTree:DeleteSubUpdate(task.TaskID)
	    end
		Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
	end
	Karm.GUI.TaskWindowOpen = false
end

function Karm.DeleteTask(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	for i = 1,#taskList do
		if taskList[i].Key == Karm.Globals.ROOTKEY then
			-- Root node  deleting requested
			wx.wxMessageBox("Cannot delete the root node!","Root Node Deleting", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		end
	end	
	local confirm
	if #taskList > 1 then
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"Are you sure you want to delete all selected tasks and all their child elements?", "Confirm Multiple Delete", wx.wxYES_NO + wx.wxNO_DEFAULT)
	else
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"Are you sure you want to delete this task:\n"..taskList[1].Title.."\n and all its child elements?", "Confirm Delete", wx.wxYES_NO + wx.wxNO_DEFAULT)
	end
	local response = confirm:ShowModal()
	if response == wx.wxID_YES then
		for i = 1,#taskList do
			-- Delete from Spores
			if taskList[i].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
				-- This is a Spore node
				Karm.SporeData[taskList[i].Key:sub(#Karm.Globals.ROOTKEY+1,-1)] = nil
				Karm.SporeData[0] = Karm.SporeData[0] - 1
				Karm.Globals.unsavedSpores[taskList[i].Key:sub(#Karm.Globals.ROOTKEY+1,-1)] = nil
			else
				-- This is a normal task
				Karm.TaskObject.DeleteFromDB(taskList[i].Task)
				Karm.Globals.unsavedSpores[taskList[i].Task.SporeFile] = Karm.SporeData[taskList[i].Task.SporeFile].Title
			end
			Karm.GUI.taskTree:DeleteTree(taskList[i].Key)
		end
	end
end

function Karm.CopyTaskToggle(event)
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_BELOW,nil)
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end			
	if #taskList > 1 then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_BELOW,nil)
        wx.wxMessageBox("Just select a single task to copy.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end	
	if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_BELOW,nil)
		wx.wxMessageBox("Cannot copy the root node or a Spore node. Please select a task to be copied.", "No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		return
	end	
	Karm.GUI.ResetMoveTools()
	Karm.GUI.CopyTask = {}
	-- Check if any other button is toggled then reset that button
	local ID = event:GetId()
	Karm.GUI.CopyTask.action = ID
	Karm.GUI.CopyTask.task = taskList[1].Task
	local ID1, ID2, status
	if ID == Karm.GUI.ID_COPY_UNDER then
		ID1 = Karm.GUI.ID_COPY_ABOVE
		ID2 = Karm.GUI.ID_COPY_BELOW
		status = "COPY TASK: Click task to copy this task under..."
	elseif ID == Karm.GUI.ID_COPY_ABOVE then
		ID1 = Karm.GUI.ID_COPY_UNDER
		ID2 = Karm.GUI.ID_COPY_BELOW
		status = "COPY TASK: Click task to copy this task above..."
	else
		ID1 = Karm.GUI.ID_COPY_ABOVE
		ID2 = Karm.GUI.ID_COPY_UNDER
		status = "COPY TASK: Click Task to copy this task below..."
	end	
	if Karm.GUI.toolbar:GetToolState(ID1) then
		Karm.GUI.toolbar:ToggleTool(ID1,nil)
	end
	if Karm.GUI.toolbar:GetToolState(ID2) then
		Karm.GUI.toolbar:ToggleTool(ID2,nil)
	end
	if not (Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_COPY_ABOVE) or Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_COPY_UNDER) or Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_COPY_BELOW)) then
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.CopyTask = nil
		return
	end
	Karm.GUI.frame:SetStatusText(status,0)
	Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.highLightColor.Red,Karm.GUI.highLightColor.Green,Karm.GUI.highLightColor.Blue))
end

function Karm.MoveTaskToggle(event)
	-- Get the selected task
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
        wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end			
	if #taskList > 1 then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
        wx.wxMessageBox("Just select a single task to move.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end	
	if taskList[1].Key:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
		Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
		wx.wxMessageBox("Cannot move the root node or a Spore node. Please select a task to be moved.", "No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		return
	end	
	Karm.GUI.ResetCopyTools()
	Karm.GUI.MoveTask = {}
	-- Check if any other button is toggled then reset that button
	local ID = event:GetId()
	Karm.GUI.MoveTask.action = ID
	Karm.GUI.MoveTask.task = taskList[1].Task
	local ID1, ID2, status
	if ID == Karm.GUI.ID_MOVE_UNDER then
		ID1 = Karm.GUI.ID_MOVE_ABOVE
		ID2 = Karm.GUI.ID_MOVE_BELOW
		status = "MOVE TASK: Click task to move this task under..."
	elseif ID == Karm.GUI.ID_MOVE_ABOVE then
		ID1 = Karm.GUI.ID_MOVE_UNDER
		ID2 = Karm.GUI.ID_MOVE_BELOW
		status = "MOVE TASK: Click task to move this task above..."
	else
		ID1 = Karm.GUI.ID_MOVE_ABOVE
		ID2 = Karm.GUI.ID_MOVE_UNDER
		status = "MOVE TASK: Click Task to move this task below..."
	end	
	if Karm.GUI.toolbar:GetToolState(ID1) then
		Karm.GUI.toolbar:ToggleTool(ID1,nil)
	end
	if Karm.GUI.toolbar:GetToolState(ID2) then
		Karm.GUI.toolbar:ToggleTool(ID2,nil)
	end
	if not (Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_MOVE_ABOVE) or Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_MOVE_UNDER) or Karm.GUI.toolbar:GetToolState(Karm.GUI.ID_MOVE_BELOW)) then
		Karm.GUI.statusBar:SetStatusText("",0)
		Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.defaultColor.Red,Karm.GUI.defaultColor.Green,Karm.GUI.defaultColor.Blue))
		Karm.GUI.MoveTask = nil
		return
	end
	Karm.GUI.frame:SetStatusText(status,0)
	Karm.GUI.statusBar:SetBackgroundColour(wx.wxColour(Karm.GUI.highLightColor.Red,Karm.GUI.highLightColor.Green,Karm.GUI.highLightColor.Blue))
end

function Karm.GUI.ResetCopyTools()
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_UNDER,nil)
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_ABOVE,nil)
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_COPY_BELOW,nil)
end

function Karm.GUI.ResetMoveTools()
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
	Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
end

function Karm.GUI.ResetToggleTools()
	Karm.GUI.ResetMoveTools()
	Karm.GUI.ResetCopyTools()
end

function Karm.EditTask(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	if not Karm.GUI.TaskWindowOpen then
		-- Get the selected task
		local taskList = Karm.GUI.taskTree.Selected
		if #taskList == 0 then
            wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end			
		if #taskList > 1 then
            wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end		
		-- Get the new task task ID
		local taskID = taskList[1].Key
		if taskID == Karm.Globals.ROOTKEY then
			-- Root node editing requested
			wx.wxMessageBox("Nothing editable in the root node","Root Node Editing", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		elseif taskID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- Spore node editing requested
			wx.wxMessageBox("Nothing editable in the spore node","Spore Node Editing", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
			return
		else
			-- A normal task editing requested
			Karm.GUI.TaskWindowOpen = {Task = taskList[1].Task}
			Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.EditTaskCallBack,taskList[1].Task)
		end
	end
end

function Karm.NewTask(event, title)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	if not Karm.GUI.TaskWindowOpen then
		local taskList = Karm.GUI.taskTree.Selected
		if #taskList == 0 then
            wx.wxMessageBox("Select a task first.","No Task Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end			
		if #taskList > 1 then
            wx.wxMessageBox("Just select a single task as the relative of the new task.","Multiple Tasks selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
            return
		end		
		-- Get the new task task ID
		local relativeID = taskList[1].Key
		local task = {}
		Karm.TaskObject.MakeTaskObject(task)
		-- There are 4 levels that need to be handled
		-- 1. Root node on the tree
		-- 2. Spore Node
		-- 3. Root task node in a Spore
		-- 4. Normal task node
		if relativeID == Karm.Globals.ROOTKEY then
			-- 1. Root node on the tree
			if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK or event:GetId() == Karm.GUI.ID_NEW_NEXT_TASK then
	            wx.wxMessageBox("A sibling for the root node cannot be created.","Root Node Sibling", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	            return
			end						
			-- This is the root so the request is to create a new spore
			Karm.createNewSpore(title)
		elseif relativeID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then
			-- 2. Spore Node
			if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK or event:GetId() == Karm.GUI.ID_NEW_NEXT_TASK then
				local rel
				if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK then
					rel = "PREV SIBLING"
				else
					rel = "NEXT SIBLING"
				end
				Karm.createNewSpore(title, rel, relativeID)
			else
				-- This is a Spore so the request is to create a new root task in the spore
				task.TaskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", "New Task", "")
				if task.TaskID == "" then
					return
				end
				-- Check if the task ID exists in all the loaded spores
				while true do
					local redo = nil
					for k,v in pairs(Karm.SporeData) do
	        			if k~=0 then
							local taskList = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=task.TaskID}}}, v)
							if #taskList > 0 then
								redo = true
								break
							end
						end
					end
					if redo then
						task.TaskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", "New Task", "")
						if task.TaskID == "" then
							return
						end
					else
						break
					end
				end		
				-- Parent of a root node is nil		
				task.SporeFile = string.sub(Karm.GUI.taskTree.Nodes[relativeID].Key,#Karm.Globals.ROOTKEY+1,-1)
				Karm.GUI.TaskWindowOpen = {Spore = true, Relative = relativeID, Relation = "Child"}
				if title then
					task.Title = title
					task.Who = {[0]="Who", count = 1, [1] = {ID = Karm.Globals.User, Status = "Active"}}
					task.Private = false
					task.Modified = true
					task.Status = "Not Started"
					if type(checkTask) == "function" then
						local err,msg = checkTask(task)
						if not err then
							msg = msg or "Error in the task. Please review."
							wx.wxMessageBox(msg, "Task Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
							Karm.GUI.TaskWindowOpen = nil
							return nil
						end
					end
					Karm.NewTaskCallBack(task)
				else
					Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.NewTaskCallBack,task)
				end
			end
		else
			-- 3. Root task node in a Spore
			-- 4. Normal task node
			-- This is a normal task so the request is to create a new task relative to this task
			if event:GetId() == Karm.GUI.ID_NEW_SUB_TASK then
				-- Sub task handling is same in both cases
				task.TaskID = Karm.TaskObject.getNewChildTaskID(Karm.GUI.taskTree.Nodes[relativeID].Task)
				task.Parent = Karm.GUI.taskTree.Nodes[relativeID].Task
				Karm.GUI.TaskWindowOpen = {Relative = relativeID, Relation = "Child"}
			else
				if not Karm.GUI.taskTree.Nodes[relativeID].Task.Parent then
					-- This is a spore root node so will have to ask for the task ID from the user
					task.TaskID = wx.wxGetTextFromUser("Enter a new TaskID (Blank to cancel):", "New Task", "")
					if task.TaskID == "" then
						return
					end
					-- Check if the task ID exists in all the loaded spores
					while true do
						local redo = nil
						for k,v in pairs(Karm.SporeData) do
		        			if k~=0 then
								local taskList = Karm.FilterObject.applyFilterHier({Tasks={[1]={TaskID=task.TaskID}}}, v)
								if #taskList > 0 then
									redo = true
									break
								end
							end
						end
						if redo then
							task.TaskID = wx.wxGetTextFromUser("Task ID already exists. Enter a new TaskID (Blank to cancel):", "New Task", "")
							if task.TaskID == "" then
								return
							end
						else
							break
						end
					end		
					-- Parent of a root node is nil	
				else				
					task.TaskID = Karm.TaskObject.getNewChildTaskID(Karm.GUI.taskTree.Nodes[relativeID].Task.Parent)
					task.Parent = Karm.GUI.taskTree.Nodes[relativeID].Task.Parent
				end
				if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK then
					Karm.GUI.TaskWindowOpen = {Relative = relativeID, Relation = "PREV SIBLING"}
				else
					Karm.GUI.TaskWindowOpen = {Relative = relativeID, Relation = "NEXT SIBLING"}
				end
			end
			task.SporeFile = Karm.GUI.taskTree.Nodes[relativeID].Task.SporeFile
			if title then
				task.Title = title
				task.Who = {[0]="Who", count = 1, [1] = {ID = Karm.Globals.User, Status = "Active"}}
				task.Private = false
				task.Modified = true
				task.Status = "Not Started"
				if type(checkTask) == "function" then
					local err,msg = checkTask(task)
					if not err then
						msg = msg or "Error in the task. Please review."
						wx.wxMessageBox(msg, "Task Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
						Karm.GUI.TaskWindowOpen = nil
						return nil
					end
				end
				Karm.NewTaskCallBack(task)
			else
				Karm.GUI.TaskForm.taskFormActivate(Karm.GUI.frame, Karm.NewTaskCallBack,task)
			end
		end		-- if relativeID == Karm.Globals.ROOTKEY then ends
	else
		Karm.GUI.TaskForm.frame:SetFocus()
	end	
end

function Karm.CharKeyEvent(event)
	print("Caught Keypress")
	local kc = event:GetKeyCode()
	if kc == wx.WXK_ESCAPE then
		print("Caught Escape")
		-- Check possible ESCAPE actions
		if Karm.GUI.MoveTask then
			Karm.GUI.MoveTask = nil
			Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_UNDER,nil)
			Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_ABOVE,nil)
			Karm.GUI.toolbar:ToggleTool(Karm.GUI.ID_MOVE_BELOW,nil)
		end			
	end
end

function Karm.connectKeyUpEvent(win)
	if win then
		pcall(win.Connect,win,wx.wxID_ANY, wx.wxEVT_KEY_UP, Karm.CharKeyEvent)
		local childNode = win:GetChildren():GetFirst()
		while childNode do
			Karm.connectKeyUpEvent(childNode:GetData())
			childNode = childNode:GetNext()
		end
	end
end

function Karm.SaveAllSpores(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	for k,v in pairs(Karm.SporeData) do
		if k ~= 0 then
			Karm.saveKarmSpore(k)
		end
	end
	Karm.Globals.unsavedSpores = {}
end

function Karm.saveKarmSpore(Spore)
	-- Check Spore integrity
	local file,err,path
	err = Karm.TaskObject.CheckSporeIntegrity(nil,Karm.SporeData[Spore])
	if #err > 0 then
		path = "Errors in Spore: "..Spore.."\n"
		for i = 1,#err do
			path = path.."Task: "..err[i].Task.Title.." ERROR: "..err[i].Error.."\n"
		end
		wx.wxMessageBox(path,"Integrity Error in Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		return
	end
	if Karm.SporeData[Spore].Modified then
		local notOK = true
		while notOK do
		    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Save Spore: "..Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore].Title,
		                                       "",
		                                       "",
		                                       "Karm Spore files (*.ksf)|*.ksf|Text files (*.txt)|*.txt|All files (*)|*",
		                                       wx.wxFD_SAVE)
		    if fileDialog:ShowModal() == wx.wxID_OK then
		    	if Karm.SporeData[path] then
		    		wx.wxMessageBox("Spore already exist select a different name please.","Name Conflict", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		    	else
		    		notOK = nil
			    	path = fileDialog:GetPath()
			    	file,err = io.open(path,"w+")
			    end
		    else
		    	return
		    end
		    fileDialog:Destroy()
		end
	else
		path = Spore
		file,err = io.open(path,"w+")
	end		-- if Karm.SporeData[Spore].Modified then ends
	if not file then
        wx.wxMessageBox("Unable to save as file '"..path.."'.\n "..err, "File Save Error", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
    else
    	if Spore ~= path then
    		-- Update the Spore File name in all the tasks and the root Spore
			Karm.SporeData[path] = Karm.SporeData[Spore]    
			Karm.SporeData[Spore] = nil
			Karm.SporeData[path].SporeFile = path
			Karm.SporeData[path].TaskID = Karm.Globals.ROOTKEY..path
			Karm.SporeData[path].Title = Karm.sporeTitle(path)		
			Karm.GUI.taskTree:UpdateKeys(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore],true)
			Karm.GUI.taskTree:UpdateNode(Karm.SporeData[path])
			-- Now update all sub tasks
			local taskList = Karm.FilterObject.applyFilterHier(nil,Karm.SporeData[path])
			if #taskList > 0 then
				for i = 1,#taskList do
					taskList[i].SporeFile = path
				end
			end
    	end
    	Karm.SporeData[path].Modified = false
    	file:write(Karm.Utility.tableToString2(Karm.SporeData[path]))
    	file:close()
    	Karm.Globals.unsavedSpores[Spore] = nil
    end
end

function Karm.SaveCurrSpore(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task or a spore first.","No Spore Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	local Spore
	if taskList[1].Task.SporeFile then
		Spore = taskList[1].Task.SporeFile
	else
		Spore = taskList[1].Key:sub(#Karm.Globals.ROOTKEY + 1,-1)
	end
	for i = 2,#taskList do
		if taskList[i].Task.SporeFile then
			if Spore ~= taskList[i].Task.SporeFile then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		else
			if Spore ~= taskList[i].Key:sub(#Karm.Globals.ROOTKEY + 1, -1) then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		end
	end
	-- Now Spore has the Spore that needs to be Saved
	Karm.saveKarmSpore(Spore)
end

function Karm.loadXML()
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Open XML Spore file",
                                       "",
                                       "",
                                       "XML Spore files (*.xml)|*.xml|All files (*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
		Karm.SporeData[fileDialog:GetPath()] = Karm.XML2Data(xml.load(fileDialog:GetPath()), fileDialog:GetPath())
		Karm.SporeData[fileDialog:GetPath()].Modified = true
		Karm.SporeData[0] = Karm.SporeData[0] + 1
    end
    fileDialog:Destroy()
end

-- Function to load a Spore given the Spore file path in the data structure and the GUI
-- Inputs:
-- file - the file name with full path of the Spore to load
-- commands - A table containin the set of commands on behavior
--		onlyData - if true then only the Spore Data is loaded GUI is not touched or queried
--		forceReload - if true reloads the data over the existing data
-- Returns true if successful otherwise throws an error
-- Error Codes returned:
--		 1 - Spore Already loaded
-- 		 2 - Task ID in the Spore already exists in the memory
--		 3 - No valid Spore found in the file
--		 4 - File load error
function Karm.loadKarmSpore(file, commands)
	local Spore
	do
		local safeenv = {}
		setmetatable(safeenv, {__index = Karm.Globals.safeenv})
		local f,message = loadfile(file)
		if not f then
			error({msg = "loadKarmSpore:4 "..message, code = "loadKarmSpore:4"},2)
		end
		setfenv(f,safeenv)
		f()
		if Karm.validateSpore(safeenv.t0) then
			Spore = safeenv.t0
		else
			error({msg = "loadKarmSpore:3 No valid Spore found in the file", code = "loadKarmSpore:3"},2)
		end
	end
	-- Update the SporeFile in all the tasks and set the metatable
	Spore.SporeFile = file
	-- Now update all sub tasks
	local list1 = Karm.FilterObject.applyFilterHier(nil,Spore)
	if #list1 > 0 then
		for i = 1,#list1 do
			list1[i].SporeFile = Spore.SporeFile
			Karm.TaskObject.MakeTaskObject(list1[i])
		end
	end        	
	-- First update the Karm.Globals.ROOTKEY
	Spore.TaskID = Karm.Globals.ROOTKEY..Spore.SporeFile
	-- Get list of task in the spore
	list1 = Karm.FilterObject.applyFilterHier(nil,Spore)
	local reload = nil
	-- Now check if the spore is already loaded in the dB
	for k,v in pairs(Karm.SporeData) do
		if k~=0 then
			if k == Spore.SporeFile then
				if commands.forceReload then
					-- Reload the spore
					reload = true
				else
					error({msg = "loadKarmSpore:1 Spore already loaded", code = "loadKarmSpore:1"},2)
				end
			end		-- if k == Spore.SporeFile then ends
			-- Check if any task ID is clashing with the existing tasks
			local list2 = Karm.FilterObject.applyFilterHier(nil,v)
			for i = 1,#list1 do
				for j = 1,#list2 do
					if list1[i].TaskID == list2[j].TaskID then
						error({msg = "loadKarmSpore:2 Task ID in the Spore already exists in the memory", code = "loadKarmSpore:2"},2)
					end
				end		-- for j = 1,#list2 do ends
			end		-- for i = 1,#list1 do ends
		end		-- if k~=0 then ends
	end		-- for k,v in pairs(Karm.SporeData) do ends
	if reload then
		-- Delete the current spore
		Karm.SporeData[Spore.SporeFile] = nil
		if not commands.onlyData and Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..Spore.SporeFile] then
			Karm.GUI.taskTree:DeleteTree(Karm.Globals.ROOTKEY..Spore.SporeFile)
		end
	end
	-- Load the spore here
	Karm.SporeData[Spore.SporeFile] = Spore
	Karm.SporeData[0] = Karm.SporeData[0] + 1
	if not commands.onlyData then
		-- Load the Spore in the Karm.GUI here
		Karm.GUI.addSpore(Spore.SporeFile,Spore)
	end
	return true
end

function Karm.openKarmSpore(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
    local fileDialog = wx.wxFileDialog(Karm.GUI.frame, "Open Spore file",
                                       "",
                                       "",
                                       "Karm Spore files (*.ksf)|*.ksf|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
    	local result,message = pcall(Karm.loadKarmSpore,fileDialog:GetPath(),{})
        if not result then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.\n "..message.msg,
                            "File Load Error",
                            wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        end
    end
    fileDialog:Destroy()
end		-- function Karm.openKarmSpore(event)ends

function Karm.unloadKarmSpore(Spore)
	if not Karm.SporeData[Spore] then
		error("Cannot find the Spore:"..Spore.." in loaded data",2)
	end
	Karm.SporeData[Spore] = nil
	Karm.SporeData[0] = Karm.SporeData[0] - 1
	Karm.GUI.taskTree:DeleteTree(Karm.Globals.ROOTKEY..Spore)
	Karm.Globals.unsavedSpores[Spore] = nil
end

function Karm.unloadSpore(event)
	-- Reset any toggle tools
	Karm.GUI.ResetToggleTools()
	local taskList = Karm.GUI.taskTree.Selected
	if #taskList == 0 then
        wx.wxMessageBox("Select a task or a spore first.","No Spore Selected", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
        return
	end
	local Spore
	if taskList[1].Task.SporeFile then
		Spore = taskList[1].Task.SporeFile
	else
		Spore = taskList[1].Key:sub(#Karm.Globals.ROOTKEY + 1,-1)
	end
	for i = 2,#taskList do
		if taskList[i].Task.SporeFile then
			if Spore ~= taskList[i].Task.SporeFile then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		else
			if Spore ~= taskList[i].Key:sub(#Karm.Globals.ROOTKEY + 1, -1) then
				-- All selected tasks are not in the same spore
				wx.wxMessageBox("Ambiguous Spore selection. Please select task from a single spore.","Ambiguous current Spore", wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
				return
			end
		end
	end
	-- Now Spore has the Spore that needs to be unloaded
	local confirm, response
	if Karm.Globals.unsavedSpores[Spore] then
		confirm = wx.wxMessageDialog(Karm.GUI.frame,"The spore "..Karm.Globals.unsavedSpores[Spore].." has unsaved changes. Are you sure you want to unload the spore and loose all changes?", "Loose all changes?", wx.wxYES_NO + wx.wxNO_DEFAULT)
		response = confirm:ShowModal()
	else
		response = wx.wxID_YES
	end
	if response == wx.wxID_YES then
		Karm.unloadKarmSpore(Spore)
	end
end

function Karm.GUI.menuEventHandlerFunction(ID, code, file)
	if not ID or (not code and not file) or (code and file) then
		error("menuEventHandler: invalid parameters passed, need the ID and only 1 of code chunk or file name.")
	end
	local handler
	if code then
		handler = function(event)
			local f,message = loadstring(code)
			if not f then
				error(message,1)
			end
			setfenv(f,getfenv(1))
			f()
		end
	else
		handler = function(event)
			local f,message = loadfile(file)
			if not f then
				error(message,1)
			end
			setfenv(f,getfenv(1))
			f()		
		end
	end
	return handler
end

function Karm.finalizePlanningAll(taskList)
	for i = 1,#taskList do
		Karm.finalizePlanning(taskList[i])
	end
end

-- To finalize the planning of a task and convert it to a normal schedule
function Karm.finalizePlanning(task)
	if not task.Planning then
		return
	end
	local list = Karm.TaskObject.getLatestScheduleDates(task,true)
	if list then
		local todayDate = wx.wxDateTime()
		todayDate:SetToCurrent()
		todayDate = Karm.Utility.toXMLDate(todayDate:Format("%m/%d/%Y"))	
		local list1 = Karm.TaskObject.getLatestScheduleDates(task)
		-- Compare the schedules
		local same = true
		if not list1 or #list1 ~= #list or (list1.typeSchedule ~= list.typeSchedule and 
		  not(list1.typeSchedule=="Commit" and list.typeSchedule == "Revs")) then
			same = false
		else
			for i = 1,#list do
				if list[i] ~= list1[i] then
					same = false
					break
				end
			end
		end
		if not same then
			-- Add the schedule here
			if not task.Schedules then
				task.Schedules = {}
			end
			if not task.Schedules[list.typeSchedule] then
				-- Schedule type does not exist so create it
				task.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}
			end
			-- Schedule type already exists so just add it to the next index
			local newSched = {[0]=list.typeSchedule}
			local str = "WD"
			if list.typeSchedule ~= "Actual" then
				newSched.Updated = todayDate
				str = "DP"
			else
				error("Got Actual schedule type while processing schedule.")
			end
			-- Update the period
			newSched.Period = {[0] = "Period", count = #list}
			for i = 1,#list do
				newSched.Period[i] = {[0] = str, Date = list[i]}
			end
			task.Schedules[list.typeSchedule][list.index] = newSched
			task.Schedules[list.typeSchedule].count = list.index
		end
	end		-- if list ends here
	task.Planning = nil	
	if Karm.GUI.taskTree.taskList then
		for i = 1,#Karm.GUI.taskTree.taskList do
			if Karm.GUI.taskTree.taskList[i] == task then
				-- Remove this one
				for j = i,#Karm.GUI.taskTree.taskList - 1 do
					Karm.GUI.taskTree.taskList[j] = Karm.GUI.taskTree.taskList[j + 1]
				end
				Karm.GUI.taskTree.taskList[#Karm.GUI.taskTree.taskList] = nil
				break
			end
		end
	end
	-- Check if the task passes the filter now
	local taskList = Karm.FilterObject.applyFilterList(Karm.Filter,{[1]=task})
	if #taskList == 1 then
		-- It passes the filter so update the task
		if not Karm.GUI.taskTree.Nodes[task.TaskID] then
			Karm.GUI.addTask(task)
		end
	    Karm.GUI.taskTree:UpdateNode(task)
		Karm.GUI.taskClicked(task)
		-- Update all the parents as well
		local currNode = Karm.GUI.taskTree.Nodes[task.TaskID]
		while currNode and currNode.Parent do
			currNode = currNode.Parent
			if currNode.Task then
				Karm.GUI.taskTree:UpdateNode(currNode.Task)
			end
		end
    else
    	-- Delete the task node and adjust the hier level of all the sub task hierarchy if any
    	Karm.GUI.taskTree:DeleteSubUpdate(task.TaskID)
    end
    Karm.Globals.unsavedSpores[task.SporeFile] = Karm.SporeData[task.SporeFile].Title
end		-- function Karm.finalizePlanning ends

function Karm.RunFile(file)
	local f,message = loadfile(file)
	if not f then
		wx.wxMessageBox("Error in compilation/loading: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	else
		local stat,message = pcall(f)
		if not stat then
			wx.wxMessageBox("Error Running File: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		end
	end	
end

function Karm.RunScript(script)
	local f,message = loadstring(script)
	if not f then
		wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
	else
		local stat,message = pcall(f)
		if not stat then
			wx.wxMessageBox("Error Running Script: "..message,"Error",wx.wxOK + wx.wxCENTRE, Karm.GUI.frame)
		end
	end	
end

function Karm.Macro(event)
	-- Get the macro details
	local frame = wx.wxFrame(Karm.GUI.frame, wx.wxID_ANY, "Enter Macro Details", wx.wxDefaultPosition,wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
	local MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)
		local ScriptPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local ScriptPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local InsLabel = wx.wxStaticText(ScriptPanel, wx.wxID_ANY, "Enter Script here:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
			ScriptPanelSizer:Add(InsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local ScriptBox = wx.wxTextCtrl(ScriptPanel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)
			ScriptPanelSizer:Add(ScriptBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local scriptButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local CompileButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Test Compile", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local RunButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Run", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local CancelButton = wx.wxButton(ScriptPanel, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			
			scriptButtonSizer:Add(CompileButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			scriptButtonSizer:Add(RunButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			scriptButtonSizer:Add(CancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			ScriptPanelSizer:Add(scriptButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		ScriptPanel:SetSizer(ScriptPanelSizer)
		ScriptPanelSizer:SetSizeHints(ScriptPanel)
	MainBook:AddPage(ScriptPanel, "Run Code")
		local FilePanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)
			local FilePanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)
			local FileInsLabel = wx.wxStaticText(FilePanel, wx.wxID_ANY, "Select Lua script file:", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)
			FilePanelSizer:Add(FileInsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local fileBrowseSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local FileBox = wx.wxTextCtrl(FilePanel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize)
			fileBrowseSizer:Add(FileBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)
			local BrowseButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Browse...", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			fileBrowseSizer:Add(BrowseButton,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			FilePanelSizer:Add(fileBrowseSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			local fileButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
			local FileCompileButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Test Compile", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local FileRunButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Run", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			local FileCancelButton = wx.wxButton(FilePanel, wx.wxID_ANY, "Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)
			
			fileButtonSizer:Add(FileCompileButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			fileButtonSizer:Add(FileRunButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			fileButtonSizer:Add(FileCancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
			FilePanelSizer:Add(fileButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
		FilePanel:SetSizer(FilePanelSizer)
		FilePanelSizer:SetSizeHints(FilePanel)
	MainBook:AddPage(FilePanel, "Run File")
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
	
	-- Events
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			frame:Close()
		end		
	)
	
	FileCancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			frame:Close()
		end		
	)

	RunButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadstring(ScriptBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				frame:Close()
				Karm.RunScript(ScriptBox:GetValue())
			end
		end		
	)

	FileRunButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the File
			local f,message = loadfile(FileBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation/loading: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				frame:Close()
				Karm.RunFile(FileBox:GetValue())
			end
		end		
	)

	BrowseButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
		    local fileDialog = wx.wxFileDialog(frame, "Select file",
		                                       "",
		                                       "",
		                                       "Lua files (*.lua)|*.lua|wxLua files (*.wlua)|*.wlua|All files (*)|*",
		                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
		    if fileDialog:ShowModal() == wx.wxID_OK then
		    	FileBox:SetValue(fileDialog:GetPath())
		    end
		    fileDialog:Destroy()
		end		
	)

	CompileButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadstring(ScriptBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				wx.wxMessageBox("Compilation successful","Success", wx.wxOK + wx.wxCENTRE, frame)			
			end
		end		
	)

	FileCompileButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,
		function(event)
			-- Test Compile the script
			local f,message = loadfile(FileBox:GetValue())
			if not f then
				wx.wxMessageBox("Error in compilation: "..message,"Error",wx.wxOK + wx.wxCENTRE, frame)
			else
				wx.wxMessageBox("Compilation successful","Success", wx.wxOK + wx.wxCENTRE, frame)			
			end
		end		
	)

	frame:SetSizer(MainSizer)
	frame:Layout()
	frame:Show(true)
end


function Karm.main()
    Karm.GUI.frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm",
                        wx.wxDefaultPosition, wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH),
                        wx.wxDEFAULT_FRAME_STYLE + wx.wxWANTS_CHARS)

	--Toolbar buttons plan 5/10/2012
	-- Open - open native saved data spore
	-- Save - Save everything
	-- Delete Task
	-- Set Filter
	-- Edit Task
	-- New Child
	-- New Next Sibling
	-- New Previous Sibling
	Karm.GUI.ID_LOAD_XML = Karm.NewID()
	Karm.GUI.ID_LOAD = Karm.NewID()
	Karm.GUI.ID_UNLOAD = Karm.NewID()
	Karm.GUI.ID_SAVEALL = Karm.NewID()
	Karm.GUI.ID_SAVECURR = Karm.NewID()
	Karm.GUI.ID_SET_FILTER = Karm.NewID()
	Karm.GUI.ID_NEW_SUB_TASK = Karm.NewID()
	Karm.GUI.ID_NEW_PREV_TASK = Karm.NewID()
	Karm.GUI.ID_NEW_NEXT_TASK = Karm.NewID()
	Karm.GUI.ID_EDIT_TASK = Karm.NewID()
	Karm.GUI.ID_DEL_TASK = Karm.NewID()
	Karm.GUI.ID_MOVE_UNDER = Karm.NewID()
	Karm.GUI.ID_MOVE_ABOVE = Karm.NewID()
	Karm.GUI.ID_MOVE_BELOW = Karm.NewID()
	Karm.GUI.ID_COPY_UNDER = Karm.NewID()
	Karm.GUI.ID_COPY_ABOVE = Karm.NewID()
	Karm.GUI.ID_COPY_BELOW = Karm.NewID()
	Karm.GUI.ID_LUA_MACRO = Karm.NewID()
	
	local bM
	Karm.GUI.toolbar = Karm.GUI.frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
	--local toolBmpSize = Karm.GUI.toolbar:GetToolBitmapSize()
	local toolBmpSize = wx.wxSize(16,16)
	bM = wx.wxImage("images/load_xml.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_LOAD_XML, "Load XML", wx.wxBitmap(bM), "Load XML Spore from Disk")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_LOAD, "Load", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DIR_UP, wx.wxART_MENU, toolBmpSize), "Load Spore from Disk")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_UNLOAD, "Unload", wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER, wx.wxART_MENU, toolBmpSize), "Unload current spore")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_SAVEALL, "Save All", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize), "Save All Spores to Disk")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_SAVECURR, "Save Current", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_MENU, toolBmpSize), "Save current spore to disk")
	Karm.GUI.toolbar:AddSeparator()
	bM = wx.wxImage("images/filter.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_SET_FILTER, "Set Filter", wx.wxBitmap(bM),   "Set Filter Criteria")
	bM = wx.wxImage("images/new_under.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_NEW_SUB_TASK, "Create Subtask", wx.wxBitmap(bM),   "Creat Sub-task")
	bM = wx.wxImage("images/new_below.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_NEW_NEXT_TASK, "Create Next Task", wx.wxBitmap(bM),   "Creat  Next task")
	bM = wx.wxImage("images/new_above.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_NEW_PREV_TASK, "Create Previous Task", wx.wxBitmap(bM),   "Creat Previous task")
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_EDIT_TASK, "Edit Task", wx.wxArtProvider.GetBitmap(wx.wxART_REPORT_VIEW, wx.wxART_MENU, toolBmpSize),   "Edit Task")
	bM = wx.wxImage("images/delete.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_DEL_TASK, "Delete Task", wx.wxBitmap(bM),   "Delete Task")
	bM = wx.wxImage("images/move_under.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_MOVE_UNDER, "Move Under", wx.wxBitmap(bM),   "Move Task Under...", wx.wxITEM_CHECK)
	bM = wx.wxImage("images/move_above.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_MOVE_ABOVE, "Move Above", wx.wxBitmap(bM),   "Move task above...", wx.wxITEM_CHECK)
	bM = wx.wxImage("images/move_below.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_MOVE_BELOW, "Move Below", wx.wxBitmap(bM),   "Move task below...", wx.wxITEM_CHECK)
	Karm.GUI.toolbar:AddSeparator()
	bM = wx.wxImage("images/copy_under.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_COPY_UNDER, "Copy Under", wx.wxBitmap(bM), "Copy Task Under...", wx.wxITEM_CHECK)
	bM = wx.wxImage("images/copy_above.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_COPY_ABOVE, "Copy Above", wx.wxBitmap(bM), "Copy Task Above...", wx.wxITEM_CHECK)
	bM = wx.wxImage("images/copy_below.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_COPY_BELOW, "Copy Below", wx.wxBitmap(bM), "Copy Task Below...", wx.wxITEM_CHECK)
	Karm.GUI.toolbar:AddSeparator()
	bM = wx.wxImage("images/lua_macro.png",wx.wxBITMAP_TYPE_PNG)
	bM = bM:Scale(toolBmpSize:GetWidth(),toolBmpSize:GetHeight())
	Karm.GUI.toolbar:AddTool(Karm.GUI.ID_LUA_MACRO, "Run Lua Macro", wx.wxBitmap(bM), "Run Lua Macro...")
	Karm.GUI.toolbar:Realize()

	-- Create status Bar in the window
    Karm.GUI.statusBar = Karm.GUI.frame:CreateStatusBar(2)
    -- Text for the 1st field in the status bar
    Karm.GUI.frame:SetStatusText("Welcome to Karm", 0)
    Karm.GUI.frame:SetStatusBarPane(-1)
    -- text for the second field in the status bar
    --Karm.GUI.frame:SetStatusText("Test", 1)
    -- Set the width of the second field to 25% of the whole window
    local widths = {}
    widths[1]=-3
    widths[2] = -1
    Karm.GUI.frame:SetStatusWidths(widths)
    Karm.GUI.defaultColor.Red = Karm.GUI.statusBar:GetBackgroundColour():Red()
    Karm.GUI.defaultColor.Green = Karm.GUI.statusBar:GetBackgroundColour():Green()
    Karm.GUI.defaultColor.Blue = Karm.GUI.statusBar:GetBackgroundColour():Blue()
    
    local getMenu
    getMenu = function(menuTable)
		local newMenu = wx.wxMenu()    
		for j = 1,#menuTable do
			if menuTable[j].Text and menuTable[j].HelpText and (menuTable[j].Code or menuTable[j].File) then
				local ID = Karm.NewID()
				newMenu:Append(ID,menuTable[j].Text,menuTable[j].HelpText, menuTable[j].ItemKind or wx.wxITEM_NORMAL)
				-- Connect the event for this
				Karm.GUI.frame:Connect(ID, wx.wxEVT_COMMAND_MENU_SELECTED,Karm.GUI.menuEventHandlerFunction(ID,menuTable[j].Code,menuTable[j].File))
			elseif menuTable[j].Text and menuTable[j].Menu then
				newMenu:Append(wx.wxID_ANY,menuTable[j].Text,getMenu(menuTable[j].Menu))
			end
		end
		return newMenu
    end

    -- create the menubar and attach it
    Karm.GUI.menuBar = wx.wxMenuBar()
	for i = 1,#Karm.GUI.MainMenu do
		if Karm.GUI.MainMenu[i].Text and Karm.GUI.MainMenu[i].Menu then
			Karm.GUI.menuBar:Append(getMenu(Karm.GUI.MainMenu[i].Menu),Karm.GUI.MainMenu[i].Text)
		end
	end    
--    local fileMenu = wx.wxMenu()
--    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")
--    local helpMenu = wx.wxMenu()
--    helpMenu:Append(wx.wxID_ABOUT, "&About", "About Karm")
--
--    Karm.GUI.menuBar:Append(fileMenu, "&File")
--    Karm.GUI.menuBar:Append(helpMenu, "&Help")
	-- MENU COMMANDS
    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    Karm.GUI.frame:Connect(wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW,
        function (event)
        	local count = 0 
			local sporeList = ""
			for k,v in pairs(Karm.Globals.unsavedSpores) do 
				count = count + 1 
				sporeList = sporeList..Karm.Globals.unsavedSpores[k].."\n"
			end 
			local confirm, response 
			if count > 0 then 
				confirm = wx.wxMessageDialog(Karm.GUI.frame,"The following spores:\n"..sporeList.." have unsaved changes. Are you sure you want to exit and loose all changes?", "Loose all changes?", wx.wxYES_NO + wx.wxNO_DEFAULT) 
				response = confirm:ShowModal() 
			else 
				response = wx.wxID_YES 
			end 
			if response == wx.wxID_YES then 
				Karm.GUI.frame:Destroy() 
			end
        end )
--
--    -- connect the selection event of the about menu item
--    Karm.GUI.frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
--        function (event)
--            wx.wxMessageBox('Karm is the Task and Project management application for everybody.\n'..
--                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
--                            "About Karm",
--                            wx.wxOK + wx.wxICON_INFORMATION,
--                            frame)
--        end )

    Karm.GUI.frame:SetMenuBar(Karm.GUI.menuBar)
	Karm.GUI.vertSplitWin = wx.wxSplitterWindow(Karm.GUI.frame, wx.wxID_ANY, wx.wxDefaultPosition, 
						wx.wxSize(Karm.GUI.initFrameW, Karm.GUI.initFrameH), wx.wxSP_3D, "Main Vertical Splitter")
	Karm.GUI.vertSplitWin:SetMinimumPaneSize(10)
	
	Karm.GUI.taskTree = Karm.GUI.newTreeGantt(Karm.GUI.vertSplitWin)
	
	-- Panel to contain the task details and filter criteria text boxes
	local detailsPanel = wx.wxPanel(Karm.GUI.vertSplitWin, wx.wxID_ANY, wx.wxDefaultPosition, 
							wx.wxDefaultSize, wx.wxTAB_TRAVERSAL, "Task Details Parent Panel")
	-- Main sizer in the detailsPanel containing everything
	local boxSizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	-- Static Box sizer to place the text boxes horizontally (Note: This sizer displays a border and some text on the top)
	local staticBoxSizer1 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Task Details")
	
	-- Task Details text box
	Karm.GUI.taskDetails = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Task Selected", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Details Box")
	staticBoxSizer1:Add(Karm.GUI.taskDetails, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer1:Add(staticBoxSizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	-- Box sizer on the right size to place the Criteria text box and above that the sizer containing the date picker control
	--   to set the dates displayed in the Gantt Grid
	local boxSizer2 = wx.wxBoxSizer(wx.wxVERTICAL)
	-- Sizer inside box sizer2 containing the date picker controls
	local boxSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)
	Karm.GUI.dateStartPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
	local startDate = Karm.GUI.dateStartPick:GetValue()
	local month = wx.wxDateSpan(0,1,0,0)
	Karm.GUI.dateFinPick = wx.wxDatePickerCtrl(detailsPanel, wx.wxID_ANY,startDate:Add(month), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)
	boxSizer3:Add(Karm.GUI.dateStartPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer3:Add(Karm.GUI.dateFinPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer2:Add(boxSizer3,0, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	local staticBoxSizer2 = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, detailsPanel, "Filter Criteria")
	Karm.GUI.taskFilter = wx.wxTextCtrl(detailsPanel, wx.wxID_ANY, "No Filter", 
						wx.wxDefaultPosition, wx.wxDefaultSize, bit.bor(wx.wxTE_AUTO_SCROLL, 
						wx.wxTE_MULTILINE, wx.wxTE_READONLY), wx.wxDefaultValidator,"Task Filter Criteria")
	staticBoxSizer2:Add(Karm.GUI.taskFilter, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 2)
	boxSizer2:Add(staticBoxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	boxSizer1:Add(boxSizer2, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 
						wx.wxALIGN_CENTER_VERTICAL), 1)
	detailsPanel:SetSizer(boxSizer1)
	boxSizer1:Fit(detailsPanel)
	boxSizer1:SetSizeHints(detailsPanel)
	Karm.GUI.vertSplitWin:SplitHorizontally(Karm.GUI.taskTree.horSplitWin, detailsPanel)
	Karm.GUI.vertSplitWin:SetSashPosition(0.7*Karm.GUI.initFrameH)

	-- ********************EVENTS***********************************************************************
	-- Date Picker Events
	Karm.GUI.dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,Karm.GUI.dateRangeChangeEvent)
	Karm.GUI.dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,Karm.GUI.dateRangeChangeEvent)
	
	-- Frame resize event
	Karm.GUI.frame:Connect(wx.wxEVT_SIZE, Karm.GUI.frameResize)
	
	-- Task Details click event
	Karm.GUI.taskDetails:Connect(wx.wxEVT_LEFT_DOWN,function(event) print(menuItems) end)
	
	-- Toolbar button events
	Karm.GUI.frame:Connect(Karm.GUI.ID_LOAD_XML,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.loadXML)
	Karm.GUI.frame:Connect(Karm.GUI.ID_SET_FILTER,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.SetFilter)
	Karm.GUI.frame:Connect(Karm.GUI.ID_NEW_SUB_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.NewTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_NEW_NEXT_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.NewTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_NEW_PREV_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.NewTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_EDIT_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.EditTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_DEL_TASK,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.DeleteTask)
	Karm.GUI.frame:Connect(Karm.GUI.ID_MOVE_UNDER,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.MoveTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_MOVE_ABOVE,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.MoveTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_MOVE_BELOW,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.MoveTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_COPY_UNDER,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.CopyTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_COPY_ABOVE,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.CopyTaskToggle)
	Karm.GUI.frame:Connect(Karm.GUI.ID_COPY_BELOW,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.CopyTaskToggle)
	
	Karm.GUI.frame:Connect(Karm.GUI.ID_SAVECURR,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.SaveCurrSpore)
	Karm.GUI.frame:Connect(Karm.GUI.ID_LOAD,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.openKarmSpore)
	Karm.GUI.frame:Connect(Karm.GUI.ID_UNLOAD,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.unloadSpore)
	Karm.GUI.frame:Connect(Karm.GUI.ID_SAVEALL,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.SaveAllSpores)
	
	Karm.GUI.frame:Connect(Karm.GUI.ID_LUA_MACRO,wx.wxEVT_COMMAND_MENU_SELECTED,Karm.Macro)

    -- Task selection in task tree
    Karm.GUI.taskTree:associateEventFunc({cellClickCallBack = Karm.GUI.taskClicked})
    -- *******************EVENTS FINISHED***************************************************************
    Karm.GUI.frame:Layout() -- help sizing the windows before being shown
    Karm.GUI.dateRangeChange()	-- To create the colums for the current date range in the GanttGrid

    Karm.GUI.taskTree:layout()
    
    -- Fill the task tree now
    Karm.GUI.fillTaskTree()
		
    wx.wxGetApp():SetTopWindow(Karm.GUI.frame)
    
	-- Key Press events
	--connectKeyUpEvent(Karm.GUI.frame)

	-- Get the user ID
    Karm.GUI.frame:Show(true)
	if not Karm.Globals.User then
		local user = ""
		while user == "" do
			user = wx.wxGetTextFromUser("Enter the user ID", "User ID", "")
		end
		Karm.Globals.User = user
	end
    Karm.GUI.frame:SetTitle("Karm ("..Karm.Globals.User..")")
end

function Karm.Initialize()
	-- Show the Splash Screen
	wx.wxInitAllImageHandlers()
	local splash = wx.wxFrame( wx.NULL, wx.wxID_ANY, "Karm", wx.wxDefaultPosition, wx.wxSize(400, 300),
                        wx.wxSTAY_ON_TOP + wx.wxFRAME_NO_TASKBAR)
    local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
    --local textBox = wx.wxTextCtrl(splash, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_CENTRE + wx.wxBORDER_NONE + wx.wxTE_READONLY)
    --local dc = wx.wxPaintDC(textBox)
    --local wid,height
    --textBox:SetFont(wx.wxFont(30, wx.wxFONTFAMILY_SWISS, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD))
    --wid,height = dc:GetTextExtent("Karm",wx.wxFont(30, wx.wxFONTFAMILY_ROMAN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD) )
    --local textAttr = wx.wxTextAttr()
    --textBox:WriteText("Karm")
    --sizer:Add(textBox, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
    local panel = wx.wxPanel(splash, wx.wxID_ANY)
	local image = wx.wxImage("images/SplashImage.jpg",wx.wxBITMAP_TYPE_JPEG)
	--image = image:Scale(100,100)
    sizer:Add(panel, 1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
    local textBox = wx.wxTextCtrl(splash, wx.wxID_ANY, "Version: "..Karm.Globals.KARM_VERSION, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_CENTRE + wx.wxBORDER_NONE + wx.wxTE_READONLY)
    sizer:Add(textBox, 0, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)
    panel:Connect(wx.wxEVT_PAINT,function(event)
		    local cdc = wx.wxPaintDC(event:GetEventObject():DynamicCast("wxWindow"))
		    cdc:DrawBitmap(wx.wxBitmap(image),11,0,false)
		    cdc:delete()
	    end
	)
    splash:SetSizer(sizer)
    splash:Centre()
    splash:Layout()
    splash:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    splash:Show(true)
    local timer = wx.wxTimer(splash)
    splash:Connect(wx.wxEVT_TIMER,function(event)
    							splash:Close()
    							timer:Stop()
								Karm.main()
    						end)
    timer:Start(3000, true)
    
	local configFile = "KarmConfig.lua"
	local f=io.open(configFile,"r")
	if f~=nil then 
		io.close(f) 
		-- load the configuration file
		dofile(configFile)
	end
	-- Load all the XML spores
	local count = 1
	Karm.SporeData[0] = 0
	-- print(Spores[count])
	if Karm.Spores then
		while Karm.Spores[count] do
			if Karm.Spores[count].type == "XML" then
				-- XML file
				Karm.SporeData[Karm.Spores[count].file] = Karm.XML2Data(xml.load(Karm.Spores[count].file), Karm.Spores[count].file)
				Karm.SporeData[Karm.Spores[count].file].Modified = true
				Karm.SporeData[0] = Karm.SporeData[0] + 1
			else
				-- Normal Karm File
				local result,message = pcall(Karm.loadKarmSpore,Karm.Spores[count].file, {onlyData=true})
			end
			count = count + 1
		end
	end
end

-- Do all the initial Configuration and Initialization
Karm.Initialize()

--main()

-- refreshTree()
-- fillDummyData()

-- updateTree(Karm.SporeData)


-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
