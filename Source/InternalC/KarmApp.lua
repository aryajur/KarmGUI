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
		__MANY2ONEFILES['CustomWidgets']="-----------------------------------------------------------------------------\r\
-- Application: Various\r\
-- Purpose:     Custom widgets using wxwidgets\r\
-- Author:      Milind Gupta\r\
-- Created:     2/09/2012\r\
-- Requirements:WxWidgets should be present already in the lua space\r\
-----------------------------------------------------------------------------\r\
local prin\r\
if Karm.Globals.__DEBUG then\r\
	prin = print\r\
end\r\
local error = error\r\
local print = prin \r\
local wx = wx\r\
local bit = bit\r\
local type = type\r\
local string = string\r\
local tostring = tostring\r\
local tonumber = tonumber\r\
local pairs = pairs\r\
local getfenv = getfenv\r\
local setfenv = setfenv\r\
local compareDateRanges = Karm.Utility.compareDateRanges\r\
local combineDateRanges = Karm.Utility.combineDateRanges\r\
\r\
\r\
local NewID = Karm.NewID    -- This is a function to generate a unique wxID for the application this module is used in\r\
\r\
local modname = ...\r\
module(modname)\r\
\r\
if not NewID then\r\
	local ID_IDCOUNTER = wx.wxID_HIGHEST + 1\r\
	function NewID()\r\
	    ID_IDCOUNTER = ID_IDCOUNTER + 1\r\
	    return ID_IDCOUNTER\r\
	end\r\
end\r\
	\r\
-- Object to generate and manage a check list \r\
do\r\
	local objMap = {}		-- private static variable\r\
	local imageList\r\
	\r\
	local getSelectedItems = function(o)\r\
		local selItems = {}\r\
		local itemNum = -1\r\
\r\
		while o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED) ~= -1 do\r\
			itemNum = o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
			local str\r\
			local item = wx.wxListItem()\r\
			item:SetId(itemNum)\r\
			item:SetMask(wx.wxLIST_MASK_IMAGE)\r\
			o.List:GetItem(item)\r\
			if item:GetImage() == 0 then\r\
				-- Item checked\r\
				str = o.checkedText\r\
			else\r\
				-- Item Unchecked\r\
				str = o.uncheckedText\r\
			end\r\
			item:SetId(itemNum)\r\
			item:SetColumn(1)\r\
			item:SetMask(wx.wxLIST_MASK_TEXT)\r\
			o.List:GetItem(item)\r\
			-- str = item:GetText()..\",\"..str\r\
			selItems[#selItems + 1] = {itemText=item:GetText(),checked=str}\r\
		end\r\
		return selItems\r\
	end\r\
		\r\
	local getAllItems = function(o)\r\
		local selItems = {}\r\
		local itemNum = -1\r\
\r\
		while o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL) ~= -1 do\r\
			itemNum = o.List:GetNextItem(itemNum,wx.wxLIST_NEXT_ALL)\r\
			local str\r\
			local item = wx.wxListItem()\r\
			item:SetId(itemNum)\r\
			item:SetMask(wx.wxLIST_MASK_IMAGE)\r\
			o.List:GetItem(item)\r\
			if item:GetImage() == 0 then\r\
				-- Item checked\r\
				str = o.checkedText\r\
			else\r\
				-- Item Unchecked\r\
				str = o.uncheckedText\r\
			end\r\
			item:SetId(itemNum)\r\
			item:SetColumn(1)\r\
			item:SetMask(wx.wxLIST_MASK_TEXT)\r\
			o.List:GetItem(item)\r\
			-- str = item:GetText()..\",\"..str\r\
			selItems[#selItems + 1] = {itemText=item:GetText(),checked=str}\r\
		end\r\
		return selItems\r\
	end\r\
\r\
	local InsertItem = function(o,Item,checked)\r\
		local ListBox = o.List\r\
		-- Check if the Item exists in the list control\r\
		local itemNum = -1\r\
		-- print(ListBox:GetNextItem(itemNum))\r\
		while ListBox:GetNextItem(itemNum) ~= -1 do\r\
			local prevItemNum = itemNum\r\
			itemNum = ListBox:GetNextItem(itemNum)\r\
			local obj = wx.wxListItem()\r\
			obj:SetId(itemNum)\r\
			obj:SetColumn(1)\r\
			obj:SetMask(wx.wxLIST_MASK_TEXT)\r\
			ListBox:GetItem(obj)\r\
			local itemText = obj:GetText()\r\
			if itemText == Item then\r\
				-- Get checked status and update\r\
				if checked then\r\
					ListBox:SetItemImage(itemNum,0)\r\
				else\r\
					ListBox:SetItemImage(itemNum,1)\r\
				end				\r\
				return true\r\
			end\r\
			if itemText > Item then\r\
				itemNum = prevItemNum\r\
				break\r\
			end \r\
		end\r\
		-- itemNum contains the item after which to place item\r\
		if itemNum == -1 then\r\
			itemNum = 0\r\
		else \r\
			itemNum = itemNum + 1\r\
		end\r\
		local newItem = wx.wxListItem()\r\
		local img\r\
		newItem:SetId(itemNum)\r\
		--newItem:SetText(Item)\r\
		if checked then\r\
			newItem:SetImage(0)\r\
		else\r\
			newItem:SetImage(1)\r\
		end				\r\
		--newItem:SetTextColour(wx.wxColour(wx.wxBLACK))\r\
		ListBox:InsertItem(newItem)\r\
		ListBox:SetItem(itemNum,1,Item)\r\
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)		\r\
		ListBox:SetColumnWidth(1,wx.wxLIST_AUTOSIZE)		\r\
		return true\r\
	end\r\
\r\
	local ResetCtrl = function(o)\r\
		o.List:DeleteAllItems()\r\
		o.List:SetImageList(imageList,wx.wxIMAGE_LIST_SMALL)\r\
	end\r\
\r\
	local RightClick = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local o = objMap[event:GetId()]\r\
		--o.List:SetImageList(o.mageList,wx.wxIMAGE_LIST_SMALL)\r\
		local item = wx.wxListItem()\r\
		local itemNum = event:GetIndex()\r\
		item:SetId(itemNum)\r\
		item:SetMask(wx.wxLIST_MASK_IMAGE)\r\
		o.List:GetItem(item)\r\
		if item:GetImage() == 0 then\r\
			--item:SetImage(1)\r\
			o.List:SetItemColumnImage(item:GetId(),0,1)\r\
		else\r\
			--item:SetImage(0)\r\
			o.List:SetItemColumnImage(item:GetId(),0,0)\r\
		end\r\
		event:Skip()\r\
	end\r\
\r\
	CheckListCtrl = function(parent,noneSelection,checkedText,uncheckedText,singleSelection)\r\
		if not parent then\r\
			return nil\r\
		end\r\
		local o = {ResetCtrl = ResetCtrl, InsertItem = InsertItem, getSelectedItems = getSelectedItems, getAllItems = getAllItems}	-- new object\r\
		o.Sizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
		o.checkedText = checkedText or \"YES\"\r\
		o.uncheckedText = uncheckedText or \"NO\"\r\
		local ID\r\
		ID = NewID()	\r\
		if singleSelection then	\r\
			o.List = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_SINGLE_SEL+wx.wxLC_NO_HEADER)\r\
		else\r\
			o.List = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\r\
		end\r\
		objMap[ID] = o\r\
		-- Create the imagelist and add check and uncheck icons\r\
		imageList = wx.wxImageList(16,16,true,0)\r\
		local icon = wx.wxIcon()\r\
		icon:LoadFile(\"images/checked.xpm\",wx.wxBITMAP_TYPE_XPM)\r\
		imageList:Add(icon)\r\
		icon:LoadFile(\"images/unchecked.xpm\",wx.wxBITMAP_TYPE_XPM)\r\
		imageList:Add(icon)\r\
		o.List:SetImageList(imageList,wx.wxIMAGE_LIST_SMALL)\r\
		-- Add Items\r\
		o.List:InsertColumn(0,\"Check\")\r\
		o.List:InsertColumn(1,\"Options\")\r\
		o.Sizer:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		o.List:Connect(wx.wxEVT_COMMAND_LIST_ITEM_RIGHT_CLICK, RightClick)\r\
		return o\r\
	end\r\
	\r\
end	-- CheckListCtrl ends\r\
\r\
\r\
-- Two List boxes and 2 buttons in between class\r\
do\r\
	local objMap = {}	-- Private Static variable\r\
\r\
	-- This is exposed to the module since it is a generic function for a listBox\r\
	InsertItem = function(ListBox,Item)\r\
		-- Check if the Item exists in the list control\r\
		local itemNum = -1\r\
		while ListBox:GetNextItem(itemNum) ~= -1 do\r\
			local prevItemNum = itemNum\r\
			itemNum = ListBox:GetNextItem(itemNum)\r\
			local itemText = ListBox:GetItemText(itemNum)\r\
			if itemText == Item then\r\
				return true\r\
			end\r\
			if itemText > Item then\r\
				itemNum = prevItemNum\r\
				break\r\
			end \r\
		end\r\
		-- itemNum contains the item after which to place item\r\
		if itemNum == -1 then\r\
			itemNum = 0\r\
		else \r\
			itemNum = itemNum + 1\r\
		end\r\
		local newItem = wx.wxListItem()\r\
		newItem:SetId(itemNum)\r\
		newItem:SetText(Item)\r\
		newItem:SetTextColour(wx.wxColour(wx.wxBLACK))\r\
		ListBox:InsertItem(newItem)\r\
		ListBox:SetItem(itemNum,0,Item)\r\
		ListBox:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)\r\
		return true\r\
	end\r\
	\r\
	local getSelectedItems = function(o)\r\
		-- Function to return all the selected items in an array\r\
		-- if the index 0 of the array is true then the none selection checkbox is checked\r\
		local selItems = {}\r\
		local SelList = o.SelList\r\
		local itemNum = -1\r\
		while SelList:GetNextItem(itemNum) ~= -1 do\r\
			itemNum = SelList:GetNextItem(itemNum)\r\
			local itemText = SelList:GetItemText(itemNum)\r\
			selItems[#selItems + 1] = itemText\r\
		end\r\
		-- Finally Check if none selection box exists\r\
		if o.CheckBox and o.CheckBox:GetValue() then\r\
			selItems[0] = \"true\"\r\
		end\r\
		return selItems\r\
	end\r\
	\r\
	local AddPress = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		-- Transfer all selected items from List to SelList\r\
		local item\r\
		local o = objMap[event:GetId()]\r\
		local list = o.List\r\
		local selList = o.SelList\r\
		item = list:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
		local selItems = {}\r\
		while item ~= -1 do\r\
			local itemText = list:GetItemText(item)\r\
			InsertItem(selList,itemText)			\r\
			selItems[#selItems + 1] = item	\r\
			item = list:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
		end\r\
		for i=#selItems,1,-1 do\r\
			list:DeleteItem(selItems[i])\r\
		end\r\
		if o.TextBox and o.TextBox:GetValue() ~= \"\" then\r\
			InsertItem(selList,o.TextBox:GetValue())\r\
			o.TextBox:SetValue(\"\")\r\
		end\r\
	end\r\
	\r\
	local ResetCtrl = function(o)\r\
		o.SelList:DeleteAllItems()\r\
		o.List:DeleteAllItems()\r\
		if o.CheckBox then\r\
			o.CheckBox:SetValue(false)\r\
		end\r\
	end\r\
	\r\
	local RemovePress = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		-- Transfer all selected items from SelList to List\r\
		local item\r\
		local o = objMap[event:GetId()]\r\
		local list = o.List\r\
		local selList = o.SelList\r\
		item = selList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
		local selItems = {}\r\
		while item ~= -1 do\r\
			local itemText = selList:GetItemText(item)\r\
			InsertItem(list,itemText)			\r\
			selItems[#selItems + 1] = item	\r\
			item = selList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
		end\r\
		for i=#selItems,1,-1 do\r\
			selList:DeleteItem(selItems[i])\r\
		end\r\
	end\r\
	\r\
	local AddListData = function(o,items)\r\
		if items then\r\
			for i = 1,#items do\r\
				InsertItem(o.List,items[i])\r\
			end\r\
		end\r\
	end\r\
	\r\
	local AddSelListData = function(o,items)\r\
		for i = 1,#items do\r\
			local item = o.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL)\r\
			while item ~= -1 do\r\
				local itemText = o.List:GetItemText(item)\r\
				if itemText == items[i] then\r\
					o.List:DeleteItem(item)\r\
					break\r\
				end		\r\
				item = o.List:GetNextItem(item,wx.wxLIST_NEXT_ALL)	\r\
			end\r\
			InsertItem(o.SelList,items[i])\r\
		end	\r\
	end\r\
	\r\
	MultiSelectCtrl = function(parent, LItems, RItems, noneSelection, textEntry)\r\
		if not parent then\r\
			return nil\r\
		end\r\
		LItems = LItems or {}\r\
		RItems = RItems or {} \r\
		local o = {AddSelListData=AddSelListData, AddListData=AddListData, ResetCtrl=ResetCtrl, getSelectedItems = getSelectedItems}	-- new object\r\
		-- Create the GUI elements here\r\
		o.Sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
			local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
			o.List = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\r\
			-- Add Items\r\
			--local col = wx.wxListItem()\r\
			--col:SetId(0)\r\
			o.List:InsertColumn(0,\"Options\")\r\
			o:AddListData(LItems)\r\
			sizer1:Add(o.List, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			local ID\r\
			if textEntry then\r\
				o.TextBox = wx.wxTextCtrl(parent, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize)\r\
				sizer1:Add(o.TextBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			end\r\
			if noneSelection then\r\
				ID = NewID()\r\
				local str\r\
				if type(noneSelection) ~= \"string\" then\r\
					str = \"None Also Passes\"\r\
				else\r\
					str = noneSelection\r\
				end\r\
				o.CheckBox = wx.wxCheckBox(parent, ID, str, wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				objMap[ID] = o \r\
				sizer1:Add(o.CheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			end\r\
			o.Sizer:Add(sizer1, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			local ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				ID = NewID()\r\
				o.AddButton = wx.wxButton(parent, ID, \">\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				ButtonSizer:Add(o.AddButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				objMap[ID] = o \r\
				ID = NewID()\r\
				o.RemoveButton = wx.wxButton(parent, ID, \"<\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				ButtonSizer:Add(o.RemoveButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				objMap[ID] = o\r\
			o.Sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			o.SelList = wx.wxListCtrl(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\r\
			-- Add Items\r\
			--col = wx.wxListItem()\r\
			--col:SetId(0)\r\
			o.SelList:InsertColumn(0,\"Selections\")\r\
			o:AddListData(RItems)\r\
			o.Sizer:Add(o.SelList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		-- Connect the buttons to the event handlers\r\
		o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,AddPress)\r\
		o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,RemovePress)\r\
		return o\r\
	end\r\
end\r\
--  MultiSelectCtrl ends\r\
\r\
-- Boolean Tree and Boolean buttons\r\
do\r\
\r\
	local objMap = {}	-- Private Static variable\r\
	\r\
	-- Function to convert a boolean string to a Table\r\
	-- Table elements '#AND#', '#OR#', '#NOT()#', '#NOT(AND)#' and '#NOT(OR)#' are reserved and their children are the ones \r\
	-- on which this operation is performed.\r\
	-- The table consist of:\r\
	-- 1. Item - contains the item name\r\
	-- 2. Parent - contains the parent table\r\
	-- 3. Children - contains a sequence of tables starting from index = 1 similar to the root table\r\
	local function convertBoolStr2Tab(str)\r\
		local boolTab = {Item=\"\",Parent=nil,Children = {},currChild=nil}\r\
		local strLevel = {}\r\
		local subMap = {}\r\
		\r\
		local getUniqueSubst = function(str,subMap)\r\
			if not subMap.latest then\r\
				subMap.latest = 1\r\
			else \r\
				subMap.latest = subMap.latest + 1\r\
			end\r\
			-- Generate prospective nique string\r\
			local uStr = \"A\"..tostring(subMap.latest)\r\
			local done = false\r\
			while not done do\r\
				-- Check if this unique string exists in str\r\
				while string.find(str,\"[%(%s]\"..uStr..\"[%)%s]\") or \r\
				  string.find(string.sub(str,1,string.len(uStr) + 1),uStr..\"[%)%s]\") or \r\
				  string.find(string.sub(str,-(string.len(uStr) + 1),-1),\"[%(%s]\"..uStr) do\r\
					subMap.latest = subMap.latest + 1\r\
					uStr = \"A\"..tostring(subMap.latest)\r\
				end\r\
				done = true\r\
				-- Check if the str exists in subMap mappings already replaced\r\
				for k,v in pairs(subMap) do\r\
					if k ~= \"latest\" then\r\
						while string.find(v,\"[%(%s]\"..uStr..\"[%)%s]\") or \r\
						  string.find(string.sub(v,1,string.len(uStr) + 1),uStr..\"[%)%s]\") or \r\
						  string.find(string.sub(v,-(string.len(uStr) + 1),-1),\"[%(%s]\"..uStr) do\r\
							done = false\r\
							subMap.latest = subMap.latest + 1\r\
							uStr = \"A\"..tostring(subMap.latest)\r\
						end\r\
						if done==false then \r\
							break \r\
						end\r\
					end\r\
				end		-- for k,v in pairs(subMap) do ends\r\
			end		-- while not done do ends\r\
			return uStr\r\
		end		-- function getUniqueSubst(str,subMap) ends\r\
		\r\
		local bracketReplace = function(str,subMap)\r\
			-- Function to replace brackets with substitutions and fill up the subMap (substitution map)\r\
			-- Make sure the brackets are consistent\r\
			local _,stBrack = string.gsub(str,\"%(\",\"t\")\r\
			local _,enBrack = string.gsub(str,\"%)\",\"t\")\r\
			if stBrack ~= enBrack then\r\
				error(\"String does not have consistent opening and closing brackets\",2)\r\
			end\r\
			local brack = string.find(str,\"%(\")\r\
			while brack do\r\
				local init = brack + 1\r\
				local fin\r\
				-- find the ending bracket for this one\r\
				local count = 0	-- to track additional bracket openings\r\
				for i = init,str:len() do\r\
					if string.sub(str,i,i) == \"(\" then\r\
						count = count + 1\r\
					elseif string.sub(str,i,i) == \")\" then\r\
						if count == 0 then\r\
							-- this is the matching bracket\r\
							fin = i-1\r\
							break\r\
						else\r\
							count = count - 1\r\
						end\r\
					end\r\
				end		-- for i = init,str:len() do ends\r\
				if count ~= 0 then\r\
					error(\"String does not have consistent opening and closing brackets\",2)\r\
				end\r\
				local uStr = getUniqueSubst(str,subMap)\r\
				local pre = \"\"\r\
				local post = \"\"\r\
				if init > 2 then\r\
					pre = string.sub(str,1,init-2)\r\
				end\r\
				if fin < str:len() - 2 then\r\
					post = string.sub(str,fin + 2,str:len())\r\
				end\r\
				subMap[uStr] = string.sub(str,init,fin)\r\
				str = pre..\" \"..uStr..\" \"..post\r\
				-- Now find the next\r\
				brack = string.find(str,\"%(\")\r\
			end		-- while brack do ends\r\
			str = string.gsub(str,\"%s+\",\" \")		-- Remove duplicate spaces\r\
			str = string.match(str,\"^%s*(.-)%s*$\")\r\
			return str\r\
		end		-- function(str,subMap) ends\r\
		\r\
		local OperSubst = function(str, subMap,op)\r\
			-- Function to make the str a simple OR expression\r\
			op = string.lower(string.match(op,\"%s*([%w%W]+)%s*\"))\r\
			if not(string.find(str,\" \"..op..\" \") or string.find(str,\" \"..string.upper(op)..\" \")) then\r\
				return str\r\
			end\r\
			str = string.gsub(str,\" \"..string.upper(op)..\" \", \" \"..op..\" \")\r\
			-- Starting chunk\r\
			local strt,stp,subStr = string.find(str,\"(.-) \"..op..\" \")\r\
			local uStr = getUniqueSubst(str,subMap)\r\
			local newStr = {count = 0} \r\
			newStr.count = newStr.count + 1\r\
			newStr[newStr.count] = uStr\r\
			subMap[uStr] = subStr\r\
			-- Middle chunks\r\
			strt,stp,subStr = string.find(str,\" \"..op..\" (.-) \"..op..\" \",stp-op:len()-1)\r\
			while strt do\r\
				uStr = getUniqueSubst(str,subMap)\r\
				newStr.count = newStr.count + 1\r\
				newStr[newStr.count] = uStr\r\
				subMap[uStr] = subStr			\r\
				strt,stp,subStr = string.find(str,\" \"..op..\" (.-) \"..op..\" \",stp-op:len()-1)	\r\
			end\r\
			-- Last Chunk\r\
			strt,stp,subStr = string.find(str,\"^.+ \"..op..\" (.-)$\")\r\
			uStr = getUniqueSubst(str,subMap)\r\
			newStr.count = newStr.count + 1\r\
			newStr[newStr.count] = uStr\r\
			subMap[uStr] = subStr\r\
			return newStr\r\
		end		-- local function ORsubst(str) ends\r\
		\r\
		-- First replace all quoted strings in the string with substitutions\r\
		local strSubMap = {}\r\
		local _,numQuotes = string.gsub(str,\"%'\",\"t\")\r\
		if numQuotes%2 ~= 0 then\r\
			error(\"String does not have consistent opening and closing quotes \\\"'\\\"\",2)\r\
		end\r\
		local init,fin = string.find(str,\"'.-'\")\r\
		while init do\r\
			local uStr = getUniqueSubst(str,subMap)\r\
			local pre = \"\"\r\
			local post = \"\"\r\
			if init > 1 then\r\
				pre = string.sub(str,1,init-1)\r\
			end\r\
			if fin < str:len() then\r\
				post = string.sub(str,fin + 1,str:len())\r\
			end\r\
			strSubMap[uStr] = str:sub(init,fin)\r\
			str = pre..\" \"..uStr..\" \"..post\r\
			-- Now find the next\r\
			init,fin = string.find(str,\"'.-'\")\r\
		end		-- while brack do ends\r\
		strLevel[boolTab] = str\r\
		-- Start recursive loop here\r\
		local currTab = boolTab\r\
		while currTab do\r\
			-- Remove all brackets\r\
			strLevel[currTab] = string.gsub(strLevel[currTab],\"%s+\",\" \")\r\
			strLevel[currTab] = bracketReplace(strLevel[currTab],subMap)\r\
			-- Check what type of element this is\r\
			if not(string.find(strLevel[currTab],\" or \") or string.find(strLevel[currTab],\" OR \") \r\
			  or string.find(strLevel[currTab],\" and \") or string.find(strLevel[currTab],\" AND \") \r\
			  or string.find(strLevel[currTab],\" not \") or string.find(strLevel[currTab],\" NOT \")\r\
			  or string.upper(string.sub(strLevel[currTab],1,4)) == \"NOT \"\r\
			  or subMap[strLevel[currTab]]) then\r\
				-- This is a simple element\r\
				if currTab.Item == \"#NOT()#\" then\r\
					currTab.Children[1] = {Item = strLevel[currTab],Parent=currTab}\r\
				else\r\
					currTab.Item = strLevel[currTab]\r\
					currTab.Children = nil\r\
				end\r\
				-- Return one level up\r\
				currTab = currTab.Parent\r\
				while currTab do\r\
					if currTab.currChild < #currTab.Children then\r\
						currTab.currChild = currTab.currChild + 1\r\
						currTab = currTab.Children[currTab.currChild]\r\
						break\r\
					else\r\
						currTab.currChild = nil\r\
						currTab = currTab.Parent\r\
					end\r\
				end\r\
			elseif not(string.find(strLevel[currTab],\" or \") or string.find(strLevel[currTab],\" OR \") \r\
			  or string.find(strLevel[currTab],\" and \") or string.find(strLevel[currTab],\" AND \") \r\
			  or string.find(strLevel[currTab],\" not \") or string.find(strLevel[currTab],\" NOT \")\r\
			  or string.upper(string.sub(strLevel[currTab],1,4)) == \"NOT \")\r\
			  and subMap[strLevel[currTab]] then\r\
				-- This is a substitution as a whole\r\
				local temp = strLevel[currTab] \r\
				strLevel[currTab] = subMap[temp]\r\
				subMap[temp] = nil\r\
			else\r\
				-- This is a normal expression\r\
				if string.find(strLevel[currTab],\" or \") or string.find(strLevel[currTab],\" OR \") then\r\
					-- The expression has OR operators\r\
					-- Transform to a simple OR expression\r\
					local simpStr = OperSubst(strLevel[currTab],subMap,\"OR\")\r\
					if currTab.Item == \"#NOT()#\" then\r\
						currTab.Item = \"#NOT(OR)#\"\r\
					else\r\
						currTab.Item = \"#OR#\"\r\
					end\r\
					-- Now allchildren need to be added and we must evaluate each child\r\
					for i = 1,#simpStr do\r\
						currTab.Children[#currTab.Children + 1] = {Item=\"\", Parent = currTab,Children={},currChild=nil}\r\
						strLevel[currTab.Children[#currTab.Children]] = simpStr[i]\r\
					end \r\
					currTab.currChild = 1\r\
					currTab = currTab.Children[1]\r\
				elseif string.find(strLevel[currTab],\" and \") or string.find(strLevel[currTab],\" AND \") then\r\
					-- The expression does not have OR operators but has AND operators\r\
					-- Transform to a simple AND expression\r\
					local simpStr = OperSubst(strLevel[currTab],subMap,\"AND\")\r\
					if currTab.Item == \"#NOT()#\" then\r\
						currTab.Item = \"#NOT(AND)#\"\r\
					else\r\
						currTab.Item = \"#AND#\"\r\
					end\r\
					-- Now allchildren need to be added and we must evaluate each child\r\
					for i = 1,#simpStr do\r\
						currTab.Children[#currTab.Children + 1] = {Item=\"\", Parent = currTab,Children={},currChild=nil}\r\
						strLevel[currTab.Children[#currTab.Children]] = simpStr[i]\r\
					end \r\
					currTab.currChild = 1\r\
					currTab = currTab.Children[1]\r\
				else\r\
					-- This is a NOT element\r\
					strLevel[currTab] = string.gsub(strLevel[currTab],\"NOT\", \"not\")\r\
					local elem = string.match(strLevel[currTab],\"%s*not%s+([%w%W]+)%s*\")\r\
					currTab.Item = \"#NOT()#\"\r\
					strLevel[currTab] = elem\r\
				end		-- if string.find(strLevel[currTab],\" or \") or string.find(strLevel[currTab],\" OR \") then ends\r\
			end \r\
		end		-- while currTab do ends\r\
		-- Now recurse boolTab to substitute all the strings back\r\
		local t = boolTab\r\
		if strSubMap[t.Item] then\r\
			t.Item = string.match(strSubMap[t.Item],\"'(.-)'\")\r\
		end\r\
		if t.Children then\r\
			-- Traverse the table to fill up the tree\r\
			local tIndex = {}\r\
			tIndex[t] = 1\r\
			while tIndex[t] <= #t.Children or t.Parent do\r\
				if tIndex[t] > #t.Children then\r\
					tIndex[t] = nil\r\
					t = t.Parent\r\
				else\r\
					-- Handle the current element\r\
					if strSubMap[t.Children[tIndex[t]].Item] then\r\
						t.Children[tIndex[t]].Item = strSubMap[t.Children[tIndex[t]].Item]:match(\"'(.-)'\")\r\
					end\r\
					tIndex[t] = tIndex[t] + 1\r\
					-- Check if this has children\r\
					if t.Children[tIndex[t]-1].Children then\r\
						-- go deeper in the hierarchy\r\
						t = t.Children[tIndex[t]-1]\r\
						tIndex[t] = 1\r\
					end\r\
				end		-- if tIndex[t] > #t then ends\r\
			end		-- while tIndex[t] <= #t and t.Parent do ends\r\
		end	-- if t.Children then ends\r\
		return boolTab\r\
	end		-- function convertBoolStr2Tab(str) ends\r\
\r\
	-- Function to set the boolean string expression in the tree\r\
	local function setExpression(o,str)\r\
		local t = convertBoolStr2Tab(str)\r\
		local tIndex = {}\r\
		local tNode = {}\r\
		local itemText = function(itemStr)\r\
			-- To return the item text\r\
			if itemStr == \"#AND#\" then\r\
				return \"(AND)\"\r\
			elseif itemStr == \"#OR#\" then\r\
				return \"(OR)\"\r\
			elseif itemStr == \"#NOT()#\" then\r\
				return \"NOT()\"\r\
			elseif itemStr == \"#NOT(AND)#\" then\r\
				return \"NOT(AND)\"\r\
			elseif itemStr == \"#NOT(OR)#\" then\r\
				return \"NOT(OR)\"\r\
			else\r\
				return itemStr\r\
			end\r\
		end\r\
		-- Clear the control\r\
		o:ResetCtrl()\r\
		tNode[t] = o.SelTree:AppendItem(o.SelTree:GetRootItem(),itemText(t.Item))\r\
		if t.Children then\r\
			-- Traverse the table to fill up the tree\r\
			tIndex[t] = 1\r\
			while tIndex[t] <= #t.Children or t.Parent do\r\
				if tIndex[t] > #t.Children then\r\
					tIndex[t] = nil\r\
					t = t.Parent\r\
				else\r\
					-- Handle the current element\r\
					local parentNode \r\
					parentNode = tNode[t]\r\
					tNode[t.Children[tIndex[t]]] = o.SelTree:AppendItem(parentNode,itemText(t.Children[tIndex[t]].Item)) \r\
					tIndex[t] = tIndex[t] + 1\r\
					-- Check if this has children\r\
					if t.Children[tIndex[t]-1].Children then\r\
						-- go deeper in the hierarchy\r\
						t = t.Children[tIndex[t]-1]\r\
						tIndex[t] = 1\r\
					end\r\
				end		-- if tIndex[t] > #t then ends\r\
			end		-- while tIndex[t] <= #t and t.Parent do ends\r\
		end	-- if t.Children then ends\r\
		o.SelTree:Expand(o.SelTree:GetRootItem())\r\
	end		-- local function setExpression(o,str) ends\r\
	\r\
	local treeRecRef\r\
	local treeRecurse = function(tree,node)\r\
		local itemText = tree:GetItemText(node) \r\
		if itemText == \"(AND)\" or itemText == \"(OR)\" or itemText == \"NOT(OR)\" or itemText == \"NOT(AND)\" then\r\
			local retText = \"(\" \r\
			local logic = string.lower(\" \"..string.match(itemText,\"%((.-)%)\")..\" \")\r\
			if string.sub(itemText,1,3) == \"NOT\" then\r\
				retText = \"not(\"\r\
			end\r\
			local currNode = tree:GetFirstChild(node)\r\
			retText = retText..treeRecRef(tree,currNode)\r\
			currNode = tree:GetNextSibling(currNode)\r\
			while currNode:IsOk() do\r\
				retText = retText..logic..treeRecRef(tree,currNode)\r\
				currNode = tree:GetNextSibling(currNode)\r\
			end\r\
			return retText..\")\"\r\
		elseif itemText == \"NOT()\" then\r\
			return \"not(\"..treeRecRef(tree,tree:GetFirstChild(node))..\")\"\r\
		else\r\
			return \"'\"..itemText..\"'\"\r\
		end\r\
	end\r\
	treeRecRef = treeRecurse\r\
\r\
	local BooleanExpression = function(o)\r\
		local tree = o.SelTree\r\
		local currNode = tree:GetFirstChild(tree:GetRootItem())\r\
		if currNode:IsOk() then\r\
			local expr = treeRecurse(tree,currNode)\r\
			return expr\r\
		else\r\
			return nil\r\
		end		\r\
	end\r\
		\r\
	local CopyTree = function(treeObj,srcItem,destItem)\r\
		-- This will copy the srcItem and its child tree to as a child of destItem\r\
		if not srcItem:IsOk() or not destItem:IsOk() then\r\
			error(\"Expected wxTreeItemIds\",2)\r\
		end\r\
		local tree = treeObj.SelTree\r\
		local currSrcNode = srcItem\r\
		local currDestNode = destItem\r\
		-- Copy the currSrcNode under the currDestNode\r\
		currDestNode = tree:AppendItem(currDestNode,tree:GetItemText(currSrcNode))\r\
		-- Check if any children\r\
		if tree:ItemHasChildren(currSrcNode) then\r\
			currSrcNode = tree:GetFirstChild(currSrcNode)\r\
			while true do\r\
				-- Copy the currSrcNode under the currDestNode\r\
				local currNode = tree:AppendItem(currDestNode,tree:GetItemText(currSrcNode))\r\
				-- Check if any children\r\
				if tree:ItemHasChildren(currSrcNode) then\r\
					currDestNode = currNode\r\
					currSrcNode = tree:GetFirstChild(currSrcNode)\r\
				elseif tree:GetNextSibling(currSrcNode):IsOk() then\r\
					-- There are more items in the same level\r\
					currSrcNode = tree:GetNextSibling(currSrcNode)\r\
				else\r\
					-- No children and no further siblings so go up\r\
					currSrcNode = tree:GetItemParent(currSrcNode)\r\
					currDestNode = tree:GetItemParent(currDestNode)\r\
					while not tree:GetNextSibling(currSrcNode):IsOk() and not(currSrcNode:GetValue() == srcItem:GetValue()) do\r\
						currSrcNode = tree:GetItemParent(currSrcNode)\r\
						currDestNode = tree:GetItemParent(currDestNode)\r\
					end\r\
					if currSrcNode:GetValue() == srcItem:GetValue() then\r\
						break\r\
					end\r\
					currSrcNode = tree:GetNextSibling(currSrcNode)\r\
				end		-- if tree:ItemHasChildren(currSrcNode) then ends\r\
			end		-- while true do ends\r\
		end		-- if tree:ItemHasChildren(currSrcNode) then ends\r\
	end\r\
	\r\
	local DelTree = function(treeObj,item)\r\
		if not item:IsOk() then\r\
			error(\"Expected proper wxTreeItemId\",2)\r\
		end\r\
		local tree = treeObj.SelTree\r\
		local currNode = item\r\
		if tree:ItemHasChildren(currNode) then\r\
			currNode = tree:GetFirstChild(currNode)\r\
			while true do\r\
				-- Check if any children\r\
				if tree:ItemHasChildren(currNode) then\r\
					currNode = tree:GetFirstChild(currNode)\r\
				elseif tree:GetNextSibling(currNode):IsOk() then\r\
					-- delete this node\r\
					-- There are more items in the same level\r\
					local next = tree:GetNextSibling(currNode)\r\
					tree:Delete(currNode)\r\
					currNode = next \r\
				else\r\
					-- No children and no further siblings so delete and go up\r\
					local parent = tree:GetItemParent(currNode)\r\
					tree:Delete(currNode)\r\
					currNode = parent\r\
					while not tree:GetNextSibling(currNode):IsOk() and not(currNode:GetValue() == item:GetValue()) do\r\
						parent = tree:GetItemParent(currNode)\r\
						tree:Delete(currNode)\r\
						currNode = parent\r\
					end\r\
					if currNode:GetValue() == item:GetValue() then\r\
						break\r\
					end\r\
					currNode = tree:GetNextSibling(currNode)\r\
				end		-- if tree:ItemHasChildren(currSrcNode) then ends\r\
			end		-- while true do ends\r\
		end		-- if tree:ItemHasChildren(currNode) then ends\r\
		tree:Delete(currNode)		\r\
	end\r\
	\r\
	local ResetCtrl = function(o)\r\
		if o.SelTree:GetFirstChild(o.SelTree:GetRootItem()):IsOk() then\r\
			DelTree(o,o.SelTree:GetFirstChild(o.SelTree:GetRootItem()))\r\
		end\r\
	end\r\
	\r\
	local DeletePress = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local ob = objMap[event:GetId()]\r\
		local Sel = ob.object.SelTree:GetSelections(Sel)	\r\
		-- Check if anything selected\r\
		if #Sel == 0 then\r\
			return nil\r\
		end\r\
		-- Get list of Parents\r\
		local parents = {}\r\
		-- Delete all selected\r\
		for i=1,#Sel do\r\
			local parent = ob.object.SelTree:GetItemParent(Sel[i])\r\
			local addParent = true\r\
			for j = 1,#parents do\r\
				if parents[j]:GetValue() == parent:GetValue() then\r\
					addParent = nil\r\
					break\r\
				end\r\
			end\r\
			if addParent then\r\
				parents[#parents + 1] = parent\r\
			end\r\
			if Sel[i]:GetValue() ~= ob.object.SelTree:GetRootItem():GetValue() then\r\
				DelTree(ob.object,Sel[i])\r\
			end\r\
		end\r\
		-- Check for any parents that are logic nodes with only 1 child under them\r\
		for i = 1,#parents do\r\
			if ob.object.SelTree:GetChildrenCount(parents[i],false) == 1 then\r\
				local nodeText = ob.object.SelTree:GetItemText(parents[i])\r\
				if nodeText == \"(OR)\" or nodeText == \"(AND)\" then\r\
					-- This is a logic node without NOT()\r\
					-- Delete the Parent and move the children up 1 level\r\
					-- Move it up the hierarchy\r\
					local pParent = ob.object.SelTree:GetItemParent(parents[i])\r\
					-- Copy all children to pParent\r\
					local currNode = ob.object.SelTree:GetFirstChild(parents[i])\r\
					while currNode:IsOk() do\r\
						CopyTree(ob.object,currNode,pParent)\r\
						currNode = ob.object.SelTree:GetNextSibling(currNode)\r\
					end\r\
					DelTree(ob.object,parents[i])\r\
				elseif nodeText == \"NOT(OR)\" or nodeText == \"NOT(AND)\"  then\r\
					-- Just change the text to NOT()\r\
					ob.object.SelTree:SetItemText(node,\"NOT(OR)\")\r\
				end\r\
			end\r\
		end\r\
		if ob.object.SelTree:GetChildrenCount(ob.object.SelTree:GetRootItem()) == 1 then\r\
			ob.object.DeleteButton:Disable()\r\
		end\r\
	end\r\
	\r\
	local NegatePress = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local ob = objMap[event:GetId()]\r\
		local Sel = ob.object.SelTree:GetSelections(Sel)	\r\
		-- Check if anything selected\r\
		if #Sel == 0 then\r\
			return nil\r\
		end\r\
		local parent = ob.object.SelTree:GetItemParent(Sel[1])\r\
		for i = 2,#Sel do\r\
			if ob.object.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\r\
				wx.wxMessageBox(\"For multiple selection negate they must all be under the same node.\",\"Selections not at the same level\", wx.wxOK + wx.wxCENTRE, o.parent)\r\
				return\r\
			end\r\
		end\r\
		if parent:IsOk() then\r\
			if #Sel == 1 then\r\
				-- Single Selection\r\
				-- Check if this is a Logic node\r\
				local nodeText = ob.object.SelTree:GetItemText(Sel[1])\r\
				if nodeText == \"(OR)\" or nodeText == \"(AND)\" or nodeText == \"NOT(OR)\" or nodeText == \"NOT(AND)\" or nodeText == \"NOT()\" then\r\
					-- Just negation of the node has to be done\r\
					local node = Sel[1]\r\
					if nodeText == \"(OR)\" then\r\
						ob.object.SelTree:SetItemText(node,\"NOT(OR)\")\r\
					elseif nodeText == \"(AND)\" then\r\
						ob.object.SelTree:SetItemText(node,\"NOT(AND)\")\r\
					elseif nodeText == \"NOT(OR)\" then\r\
						ob.object.SelTree:SetItemText(node,\"(OR)\")\r\
					elseif nodeText == \"NOT(AND)\" then\r\
						ob.object.SelTree:SetItemText(node,\"(AND)\")\r\
					else\r\
						-- NOT()\r\
						-- Move it up the hierarchy\r\
						local pParent = ob.object.SelTree:GetItemParent(node)\r\
						-- Copy all children to pParent\r\
						local currNode = ob.object.SelTree:GetFirstChild(node)\r\
						while currNode:IsOk() do\r\
							CopyTree(ob.object,currNode,pParent)\r\
							currNode = ob.object.SelTree:GetNextSibling(currNode)\r\
						end\r\
						DelTree(ob.object,node)\r\
					end		-- if parentText == \"(OR)\" then ends here\r\
				-- Check if the parent just has this child\r\
				elseif ob.object.SelTree:GetChildrenCount(parent,false) == 1 then\r\
					local node = parent\r\
					nodeText = ob.object.SelTree:GetItemText(parent)\r\
					if nodeText == \"(OR)\" then\r\
						ob.object.SelTree:SetItemText(node,\"NOT(OR)\")\r\
					elseif nodeText == \"(AND)\" then\r\
						ob.object.SelTree:SetItemText(node,\"NOT(AND)\")\r\
					elseif nodeText == \"NOT(OR)\" then\r\
						ob.object.SelTree:SetItemText(node,\"(OR)\")\r\
					elseif nodeText == \"NOT(AND)\" then\r\
						ob.object.SelTree:SetItemText(node,\"(AND)\")\r\
					else\r\
						-- NOT()\r\
						-- Move it up the hierarchy\r\
						local pParent = ob.object.SelTree:GetItemParent(node)\r\
						CopyTree(ob.object,Sel[1],pParent)\r\
						DelTree(ob.object,node)\r\
					end		-- if parentText == \"(OR)\" then ends here\r\
				else\r\
					local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\r\
					CopyTree(ob.object,Sel[1],currNode)\r\
					DelTree(ob.object,Sel[1])\r\
				end		-- if type of node - Logic Node, Single Child node of a parent or one of many children\r\
			else\r\
				-- Multiple Selection\r\
				-- Check if the parent just has these children\r\
				local parentText = ob.object.SelTree:GetItemText(parent)\r\
				if ob.object.SelTree:GetChildrenCount(parent,false) == #Sel then\r\
					-- Just modify the parent text\r\
					if parentText == \"(OR)\" then\r\
						ob.object.SelTree:SetItemText(parent,\"NOT(OR)\")\r\
					elseif parentText == \"(AND)\" then\r\
						ob.object.SelTree:SetItemText(parent,\"NOT(AND)\")\r\
					elseif parentText == \"NOT(OR)\" then\r\
						ob.object.SelTree:SetItemText(parent,\"(OR)\")\r\
					else -- parentText == \"NOT(AND)\" \r\
						ob.object.SelTree:SetItemText(parent,\"(AND)\")\r\
					end\r\
				else\r\
					-- First move the selections to a correct new node\r\
					if parentText == \"(OR)\" or parentText == \"NOT(OR)\" then\r\
						parentText = \"NOT(OR)\"\r\
					elseif parentText == \"(AND)\" or parentText == \"NOT(AND)\" then\r\
						parentText = \"NOT(AND)\" \r\
					end\r\
					parent = ob.object.SelTree:AppendItem(ob.object.SelTree:GetItemParent(Sel[1]),parentText)\r\
					for i = 1,#Sel do\r\
						CopyTree(ob.object,Sel[i],parent)\r\
						DelTree(ob.object,Sel[i])\r\
					end\r\
				end\r\
			end\r\
		end	-- if parent:IsOk() then\r\
	end\r\
	\r\
	local LogicPress = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local ob = objMap[event:GetId()]\r\
		-- Get the Logic Unit\r\
		local unit = ob.object.getInfo()\r\
		if not unit then\r\
			return nil\r\
		end\r\
		\r\
		local root = ob.object.SelTree:GetRootItem()\r\
		if ob.object.SelTree:GetCount() == 1 then\r\
			-- Just add this first object\r\
			local currNode = ob.object.SelTree:AppendItem(root,unit)\r\
			ob.object.SelTree:Expand(root)\r\
			return nil\r\
		end\r\
		-- More than 1 item in the tree so now find the selections and  modify the tree\r\
		local Sel = ob.object.SelTree:GetSelections(Sel)\r\
		-- Check if anything selected\r\
		if #Sel == 0 then\r\
			return nil\r\
		end\r\
		\r\
		-- Check if parent of all selections is the same	\r\
		if #Sel > 1 then\r\
        	local parent = ob.object.SelTree:GetItemParent(Sel[1])\r\
        	for i = 2,#Sel do\r\
        		if ob.object.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\r\
        			-- Parent is not common. \r\
        			wx.wxMessageBox(\"All selected items not siblings!\",\"Error applying operation\", wx.wxICON_ERROR)\r\
        			return nil\r\
        		end\r\
        	end\r\
        end\r\
		\r\
		-- Check if root node selected\r\
		if #Sel == 1 and ob.object.SelTree:GetRootItem():GetValue() == Sel[1]:GetValue() then\r\
			-- Root item selected clear Sel and fill up with all children of root\r\
			Sel = {}\r\
			local node = ob.object.SelTree:GetFirstChild(ob.object.SelTree:GetRootItem())\r\
			Sel[#Sel + 1] = node\r\
			node = ob.object.SelTree:GetNextSibling(node)\r\
			while node:IsOk() do\r\
				Sel[#Sel + 1] = node\r\
				node = ob.object.SelTree:GetNextSibling(node)\r\
			end\r\
		end\r\
		local added = nil\r\
		if #Sel > 1 then\r\
			-- Check if all children selected\r\
			local parent = ob.object.SelTree:GetItemParent(Sel[1])\r\
			if #Sel == ob.object.SelTree:GetChildrenCount(parent,false) then\r\
				-- All children of parent are selected\r\
				-- Check if the unit can be added under the parent itself\r\
				local parentText = ob.object.SelTree:GetItemText(parent)\r\
				if ((ob.button == \"AND\" or ob.button == \"NAND\" or ob.button == \"ANDN\" or ob.button == \"NANDN\") and \r\
						(parentText == \"(AND)\" or parentText == \"NOT(AND)\")) or\r\
				   ((ob.button == \"OR\" or ob.button == \"NOR\" or ob.button == \"ORN\" or ob.button == \"NORN\") and \r\
				   		(parentText == \"(OR)\" or parentText == \"NOT(OR)\")) then\r\
					-- Add the unit under parent\r\
					if ob.button == \"AND\" or ob.button == \"OR\" then\r\
						-- Add to parent directly\r\
						ob.object.SelTree:AppendItem(parent,unit)\r\
					elseif ob.button == \"NAND\" or ob.button == \"NOR\" then\r\
						-- Add to parent by negating first\r\
						local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\r\
						ob.object.SelTree:AppendItem(currNode,unit)\r\
					elseif ob.button == \"ANDN\" or ob.button == \"ORN\" or ob.button == \"NANDN\" or ob.button == \"NORN\" then\r\
						if parentText == \"(AND)\" or parentText == \"(OR)\"then\r\
							-- Move all selected to a negated subnode\r\
							local newPText \r\
							if parentText == \"(OR)\" then\r\
								newPText = \"NOT(OR)\"\r\
							elseif parentText == \"(AND)\" then\r\
								newPText = \"NOT(AND)\" \r\
							end\r\
							local newParent = ob.object.SelTree:AppendItem(parent,newPText)\r\
							for i = 1,#Sel do\r\
								CopyTree(ob.object,Sel[i],newParent)\r\
								DelTree(ob.object,Sel[i])\r\
							end\r\
						elseif parentText == \"NOT(AND)\" then\r\
							ob.object.SelTree:SetItemText(parent,\"(AND)\")\r\
						elseif parentText == \"NOT(OR)\" then\r\
							ob.object.SelTree:SetItemText(parent,\"(OR)\")\r\
						end\r\
						-- Now add the unit to the parent\r\
						if ob.button == \"NANDN\" or ob.button == \"NORN\" then\r\
							local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\r\
							ob.object.SelTree:AppendItem(currNode,unit)\r\
						else\r\
							ob.object.SelTree:AppendItem(parent,unit)\r\
						end\r\
					end\r\
					added = true\r\
				end\r\
			end		-- if #Sel < ob.object.SelTree:GetChildrenCount(parent) then ends\r\
			if not added then\r\
				-- Move all selected to sub node\r\
				local parentText = ob.object.SelTree:GetItemText(parent)\r\
				if parentText == \"(OR)\" or parentText == \"NOT(OR)\" then\r\
					parentText = \"(OR)\"\r\
				elseif parentText == \"(AND)\" or parentText == \"NOT(AND)\" then\r\
					parentText = \"(AND)\" \r\
				end\r\
				parent = ob.object.SelTree:AppendItem(ob.object.SelTree:GetItemParent(Sel[1]),parentText)\r\
				for i = 1,#Sel do\r\
					CopyTree(ob.object,Sel[i],parent)\r\
					DelTree(ob.object,Sel[i])\r\
				end\r\
				Sel = {parent}\r\
			end\r\
		end\r\
		if not added then\r\
			-- Single item selection case\r\
			-- Check if this is a logic node and the unit can directly be added to it\r\
			local selText = ob.object.SelTree:GetItemText(Sel[1])\r\
			if selText == \"(OR)\" and (ob.button == \"OR\" or ob.button == \"NOR\") then\r\
				if ob.button == \"OR\" then\r\
					-- Add to parent directly\r\
					ob.object.SelTree:AppendItem(Sel[1],unit)\r\
				else\r\
					-- Add to parent by negating first\r\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\r\
					ob.object.SelTree:AppendItem(currNode,unit)\r\
				end\r\
			elseif  selText == \"(AND)\" and (ob.button == \"AND\" or ob.button == \"NAND\") then\r\
				if ob.button == \"AND\" then\r\
					-- Add to parent directly\r\
					ob.object.SelTree:AppendItem(Sel[1],unit)\r\
				else\r\
					-- Add to parent by negating first\r\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\r\
					ob.object.SelTree:AppendItem(currNode,unit)\r\
				end\r\
			elseif selText == \"NOT(OR)\" and (ob.button == \"ORN\" or ob.button == \"NORN\") then\r\
				if ob.button == \"ORN\" then\r\
					-- Add to parent directly\r\
					ob.object.SelTree:AppendItem(Sel[1],unit)\r\
				else\r\
					-- Add to parent by negating first\r\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\r\
					ob.object.SelTree:AppendItem(currNode,unit)\r\
				end\r\
				ob.object.SelTree:SetItemText(Sel[1],\"(OR)\")\r\
			elseif selText == \"NOT(AND)\" and (ob.button == \"ANDN\" or ob.button == \"NANDN\") then\r\
				if ob.button == \"ANDN\" then\r\
					-- Add to parent directly\r\
					ob.object.SelTree:AppendItem(Sel[1],unit)\r\
				else\r\
					-- Add to parent by negating first\r\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\r\
					ob.object.SelTree:AppendItem(currNode,unit)\r\
				end\r\
				ob.object.SelTree:SetItemText(Sel[1],\"(AND)\")\r\
			elseif selText == \"NOT()\" and (ob.button == \"ANDN\" or ob.button == \"NANDN\" or ob.button == \"ORN\" or ob.button == \"NORN\")then\r\
				if ob.button == \"ANDN\" then\r\
					ob.object.SelTree:SetItemText(Sel[1],\"(AND)\")\r\
					ob.object.SelTree:AppendItem(Sel[1],unit)\r\
				elseif ob.button == \"NANDN\" then\r\
					ob.object.SelTree:SetItemText(Sel[1],\"(AND)\")\r\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\r\
					ob.object.SelTree:AppendItem(currNode,unit)\r\
				elseif ob.button == \"ORN\" then\r\
					ob.object.SelTree:SetItemText(Sel[1],\"(OR)\")\r\
					ob.object.SelTree:AppendItem(Sel[1],unit)\r\
				else\r\
					ob.object.SelTree:SetItemText(Sel[1],\"(OR)\")\r\
					local currNode = ob.object.SelTree:AppendItem(Sel[1],\"NOT()\")\r\
					ob.object.SelTree:AppendItem(currNode,unit)\r\
				end\r\
			else\r\
				-- Unit cannot be added to the selected node since that is also a unit\r\
				local parent = ob.object.SelTree:GetItemParent(Sel[1])\r\
				local parentText = ob.object.SelTree:GetItemText(parent)\r\
				-- Handle the directly adding unit to parent cases\r\
				if (parentText == \"(OR)\" or parentText == \"NOT(OR)\") and  (ob.button == \"OR\" or ob.button == \"NOR\") then\r\
					if ob.button == \"OR\" then\r\
						-- Add to parent directly\r\
						ob.object.SelTree:AppendItem(parent,unit)\r\
					else\r\
						-- Add to parent by negating first\r\
						local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\r\
						ob.object.SelTree:AppendItem(currNode,unit)\r\
					end\r\
				elseif (parentText == \"(AND)\" or parentText == \"NOT(AND)\") and (ob.button == \"AND\" or ob.button == \"NAND\") then\r\
					if ob.button == \"AND\" then\r\
						-- Add to parent directly\r\
						ob.object.SelTree:AppendItem(parent,unit)\r\
					else\r\
						-- Add to parent by negating first\r\
						local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\r\
						ob.object.SelTree:AppendItem(currNode,unit)\r\
					end\r\
				elseif parentText == \"NOT()\" and (ob.button == \"AND\" or ob.button == \"NAND\" or ob.button == \"OR\" or ob.button == \"NOR\") then\r\
					-- parentText = \"NOT()\"\r\
					-- Change Parent text\r\
					if ob.button == \"NAND\" or ob.button == \"AND\" then\r\
						ob.object.SelTree:SetItemText(parent,\"NOT(AND)\")\r\
						if ob.button == \"AND\" then\r\
							-- Add to parent directly\r\
							ob.object.SelTree:AppendItem(parent,unit)\r\
						else\r\
							-- Add to parent by negating first\r\
							local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\r\
							ob.object.SelTree:AppendItem(currNode,unit)\r\
						end\r\
					elseif ob.button==\"NOR\" or ob.button == \"OR\" then\r\
						ob.object.SelTree:SetItemText(parent,\"NOT(OR)\")\r\
						if ob.button == \"OR\" then\r\
							-- Add to parent directly\r\
							ob.object.SelTree:AppendItem(parent,unit)\r\
						else\r\
							-- Add to parent by negating first\r\
							local currNode = ob.object.SelTree:AppendItem(parent,\"NOT()\")\r\
							ob.object.SelTree:AppendItem(currNode,unit)\r\
						end\r\
					end\r\
				else\r\
					-- Now we need to move this single selected node to a new fresh node in its place and add unit also to that node\r\
					if ob.button == \"AND\" or ob.button == \"NAND\" or ob.button == \"ANDN\" or ob.button == \"NANDN\" then\r\
						parentText = \"(AND)\"\r\
					elseif ob.button == \"OR\" or ob.button == \"NOR\" or ob.button == \"ORN\" or ob.button == \"NORN\" then\r\
						parentText = \"(OR)\"\r\
					end\r\
					local currNode = ob.object.SelTree:AppendItem(parent,parentText)\r\
					if ob.button == \"ANDN\" or ob.button ==\"NANDN\" or ob.button == \"ORN\" or ob.button == \"NORN\" then\r\
						local negNode = ob.object.SelTree:AppendItem(currNode,\"NOT()\")\r\
						CopyTree(ob.object,Sel[1],negNode)\r\
					else \r\
						CopyTree(ob.object,Sel[1],currNode)\r\
					end		\r\
					DelTree(ob.object,Sel[1])\r\
					-- Add the unit\r\
					if ob.button == \"AND\" or ob.button == \"OR\" or ob.button == \"ANDN\" or ob.button == \"ORN\" then\r\
						-- Add to parent directly\r\
						ob.object.SelTree:AppendItem(currNode,unit)\r\
					else\r\
						-- Add to parent by negating first\r\
						local negNode = ob.object.SelTree:AppendItem(currNode,\"NOT()\")\r\
						ob.object.SelTree:AppendItem(negNode,unit)\r\
					end\r\
				end		-- if (parentText == \"(OR)\" or parentText == \"NOT(OR)\") and  (ob.button == \"OR\" or ob.button == \"NOR\") then ends\r\
			end		-- if selText == \"(OR)\" and (ob.button == \"OR\" or ob.button == \"NOR\") then ends\r\
		end	-- if not added then ends\r\
		--print(ob.object,ob.button)\r\
		--print(BooleanTreeCtrl.BooleanExpression(ob.object.SelTree))	\r\
	end\r\
	\r\
--[[	local TreeSelChanged = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local o = objMap[event:GetId()]\r\
        \r\
        -- Update the Delete Button status\r\
        local Sel = o.SelTree:GetSelections(Sel)\r\
        if #Sel == 0 then\r\
        	o.prevSel = {}\r\
        	o.DeleteButton:Disable()\r\
        	return nil\r\
        end\r\
        o.DeleteButton:Enable(true)\r\
    	-- Check here if there are more than 1 difference between Sel and prevSel\r\
    	local diff = 0\r\
    	for i = 1,#Sel do\r\
    		local found = nil\r\
    		for j = 1,#o.prevSel do\r\
    			if Sel[i]:GetValue() == o.prevSel[j]:GetValue() then\r\
    				found = true\r\
    				break\r\
    			end\r\
    		end\r\
    		if not found then\r\
    			diff = diff + 1\r\
    		end\r\
    	end\r\
    	-- diff has number of elements in Sel but nout found in o.prevSel\r\
    	for i = 1,#o.prevSel do\r\
    		local found = nil\r\
    		for j = 1,#Sel do\r\
    			if Sel[j]:GetValue() == o.prevSel[i]:GetValue() then\r\
    				found = true\r\
    				break\r\
    			end\r\
    		end\r\
    		if not found then\r\
    			diff = diff + 1\r\
    		end\r\
    	end\r\
        if #Sel > 1 and diff == 1 then\r\
        	-- Check here if the selection needs to be modified to keep at the same level\r\
        	local parent = o.SelTree:GetItemParent(Sel[1])\r\
        	for i = 2,#Sel do\r\
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\r\
        			-- Need to modify the selection here\r\
        			-- Find which element was selected last here\r\
        			local newElem = nil\r\
        			for j = 1,#Sel do\r\
        				local found = nil\r\
        				for k = 1,#o.prevSel do\r\
        					if Sel[j]:GetValue() == o.prevSel[k]:GetValue() then\r\
        						found = true\r\
        						break\r\
        					end\r\
        				end\r\
        				if not found then\r\
        					newElem = Sel[j]\r\
        					break\r\
        				end\r\
        			end		-- for j = 1,#Sel do ends\r\
        			-- Now newElem has the newest element so deselect everything and select that\r\
        			for j = 1,#Sel do\r\
        				o.SelTree:SelectItem(Sel[j],false)\r\
        			end\r\
        			o.SelTree:SelectItem(newElem,true)\r\
	        		Sel = o.SelTree:GetSelections(Sel)\r\
					o.prevSel = {}\r\
					for i = 1,#Sel do\r\
						o.prevSel[i] = Sel[i]\r\
					end\r\
        			break\r\
        		end		-- if o.SelTree:GetItemParent(Sel[i]) ~= parent then ends\r\
        	end		-- for i = 2,#Sel do ends\r\
        end		-- if #Sel > 1 then\r\
--        if #Sel > 1 or o.SelTree:ItemHasChildren(Sel[1]) then\r\
--        	o.DeleteButton:Disable()\r\
--        else\r\
--        	o.DeleteButton:Enable(true)\r\
--        end\r\
		-- Populate prevSel table\r\
    	if diff == 1 and math.abs(#Sel-#o.prevSel) == 1 then\r\
			o.prevSel = {}\r\
			for i = 1,#Sel do\r\
				o.prevSel[i] = Sel[i]\r\
			end\r\
		elseif diff > 1 and math.abs(#Sel-#o.prevSel) == diff then\r\
			-- Selection made by Shift Key check if at same hierarchy then update prevSel otherwise rever to prevSel\r\
        	local parent = o.SelTree:GetItemParent(Sel[1])\r\
        	local updatePrev = true\r\
        	for i = 2,#Sel do\r\
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\r\
        			-- Now newElem has the newest element so deselect everything and select that\r\
        			for j = 1,#Sel do\r\
        				o.SelTree:SelectItem(Sel[j],false)\r\
        			end\r\
        			for j = 1,#o.prevSel do\r\
        				o.SelTree:SelectItem(o.prevSel[j],true)\r\
        			end\r\
        			updatePrev = false\r\
        			break\r\
        		end		-- if o.SelTree:GetItemParent(Sel[i]) ~= parent then ends\r\
        	end		-- for i = 2,#Sel do ends	\r\
        	if updatePrev then		\r\
				o.prevSel = {}\r\
				for i = 1,#Sel do\r\
					o.prevSel[i] = Sel[i]\r\
				end\r\
			end\r\
		end\r\
		\r\
		--event:Skip()\r\
		--print(o.SelTree:GetItemText(item))\r\
	end,]]\r\
	\r\
	local TreeSelChanged = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local o = objMap[event:GetId()]\r\
        \r\
        -- Update the Delete Button status\r\
        local Sel = o.SelTree:GetSelections(Sel)\r\
        if #Sel == 0 then\r\
        	o.prevSel = {}\r\
        	o.DeleteButton:Disable()\r\
        	o.NegateButton:Disable()\r\
        	return nil\r\
        end\r\
        o.DeleteButton:Enable(true)\r\
       	o.NegateButton:Enable(true)\r\
		-- Check if parent of all selections is the same	\r\
		if #Sel > 1 then\r\
        	local parent = o.SelTree:GetItemParent(Sel[1])\r\
        	for i = 2,#Sel do\r\
        		if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then\r\
        			-- Deselect everything\r\
        			for j = 1,#Sel do\r\
        				o.SelTree:SelectItem(Sel[j],false)\r\
        			end\r\
        			-- Select the items with the largest parent\r\
        			local parents = {}	-- To store parents and their numbers\r\
        			for j =1,#Sel do\r\
        				local found = nil\r\
        				for k = 1,#parents do\r\
        					if o.SelTree:GetItemParent(Sel[j]):GetValue() == parents[k].ID:GetValue() then\r\
        						parents[k].count = parents[k].count + 1\r\
        						found = true\r\
        						break\r\
        					end\r\
        				end\r\
        				if not found then\r\
        					parents[#parents + 1] = {ID = o.SelTree:GetItemParent(Sel[j]), count = 1}\r\
        				end\r\
        			end\r\
        			-- Find parent with largest number of children\r\
        			local index = 1\r\
        			for j = 2,#parents do\r\
        				if parents[j].count > parents[index].count then\r\
        					index = j\r\
        				end\r\
        			end\r\
        			-- Select all items with parents[index].ID as parent\r\
        			for j = 1,#Sel do\r\
        				if o.SelTree:GetItemParent(Sel[j]):GetValue() == parents[index].ID:GetValue() then\r\
        					o.SelTree:SelectItem(Sel[j],true)\r\
        				end\r\
        			end		-- for j = 1,#Sel do ends\r\
        		end		-- if o.SelTree:GetItemParent(Sel[i]):GetValue() ~= parent:GetValue() then ends\r\
        	end		-- for i = 2,#Sel do ends\r\
        end		-- if #Sel > 1 then ends\r\
        event:Skip()\r\
	end\r\
	\r\
	BooleanTreeCtrl = function(parent,sizer,getInfoFunc)\r\
		if not parent or not sizer or not getInfoFunc or type(getInfoFunc)~=\"function\" then\r\
			return nil\r\
		end\r\
		local o = {ResetCtrl=ResetCtrl,BooleanExpression=BooleanExpression, setExpression = setExpression}\r\
		o.getInfo = getInfoFunc\r\
		o.prevSel = {}\r\
		o.parent = parent\r\
		local ButtonSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
			local ID = NewID()\r\
			o.ANDButton = wx.wxButton(parent, ID, \"AND\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = {object=o,button=\"AND\"}\r\
			ButtonSizer:Add(o.ANDButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			ID = NewID()\r\
			o.ORButton = wx.wxButton(parent, ID, \"OR\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = {object=o,button=\"OR\"}\r\
			ButtonSizer:Add(o.ORButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			ID = NewID()\r\
			o.NANDButton = wx.wxButton(parent, ID, \"NOT() AND\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = {object=o,button=\"NAND\"}\r\
			ButtonSizer:Add(o.NANDButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			ID = NewID()\r\
			o.NORButton = wx.wxButton(parent, ID, \"NOT() OR\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = {object=o,button=\"NOR\"}\r\
			ButtonSizer:Add(o.NORButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			ID = NewID()\r\
			o.ANDNButton = wx.wxButton(parent, ID, \"AND NOT\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = {object=o,button=\"ANDN\"}\r\
			ButtonSizer:Add(o.ANDNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			ID = NewID()\r\
			o.ORNButton = wx.wxButton(parent, ID, \"OR NOT\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = {object=o,button=\"ORN\"}\r\
			ButtonSizer:Add(o.ORNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			ID = NewID()\r\
			o.NANDNButton = wx.wxButton(parent, ID, \"NOT() AND NOT\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = {object=o,button=\"NANDN\"}\r\
			ButtonSizer:Add(o.NANDNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			ID = NewID()\r\
			o.NORNButton = wx.wxButton(parent, ID, \"NOT() OR NOT\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = {object=o,button=\"NORN\"}\r\
			ButtonSizer:Add(o.NORNButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		sizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			local treeSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				ID = NewID()\r\
				o.SelTree = wx.wxTreeCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,bit.bor(wx.wxTR_HAS_BUTTONS,wx.wxTR_MULTIPLE))\r\
				objMap[ID] = o\r\
				-- Add the root\r\
				local root = o.SelTree:AddRoot(\"Expressions\")\r\
				o.SelTree:SelectItem(root)\r\
			treeSizer:Add(o.SelTree, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				-- Add the Delete and Negate Buttons\r\
				ButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					ID = NewID()\r\
					o.DeleteButton = wx.wxButton(parent, ID, \"Delete\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
					objMap[ID] = {object=o,button=\"Delete\"}\r\
				ButtonSizer:Add(o.DeleteButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				o.DeleteButton:Disable()\r\
					ID = NewID()\r\
					o.NegateButton = wx.wxButton(parent, ID, \"Negate\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
					objMap[ID] = {object=o,button=\"Negate\"}\r\
				ButtonSizer:Add(o.NegateButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				o.NegateButton:Disable()\r\
			treeSizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)		\r\
		sizer:Add(treeSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	\r\
		-- Connect the buttons to the event handlers\r\
		o.ANDButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\r\
		o.ORButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\r\
		o.NANDButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\r\
		o.NORButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\r\
		o.ANDNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\r\
		o.ORNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\r\
		o.NANDNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\r\
		o.NORNButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,LogicPress)\r\
		o.DeleteButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,DeletePress)\r\
		o.NegateButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,NegatePress)\r\
		\r\
		-- Connect the tree to the left click event\r\
		o.SelTree:Connect(wx.wxEVT_COMMAND_TREE_SEL_CHANGED, TreeSelChanged)\r\
		return o\r\
	end\r\
end		-- BooleanTreeCtrl ends\r\
\r\
-- Control to select date Range\r\
do\r\
	local objMap = {}\r\
	SelectDateRangeCtrl = function(parent,numInstances,returnFunc)\r\
		if not objMap[parent] then\r\
			objMap[parent] = 1\r\
		elseif objMap[parent] >= numInstances then\r\
			return false\r\
		else\r\
			objMap[parent] = objMap[parent] + 1\r\
		end\r\
		local drFrame = wx.wxFrame(parent, wx.wxID_ANY, \"Date Range Selection\", wx.wxDefaultPosition,\r\
			wx.wxDefaultSize, wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION\r\
			+ wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN)\r\
		local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
		local calSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
		local fromSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
		local label = wx.wxStaticText(drFrame, wx.wxID_ANY, \"From:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
		fromSizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		local fromDate = wx.wxCalendarCtrl(drFrame,wx.wxID_ANY)\r\
		fromSizer:Add(fromDate, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
		local toSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
		label = wx.wxStaticText(drFrame, wx.wxID_ANY, \"To:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
		toSizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		local toDate = wx.wxCalendarCtrl(drFrame,wx.wxID_ANY)\r\
		toSizer:Add(toDate, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		\r\
		calSizer:Add(fromSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		calSizer:Add(toSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		\r\
		-- Add Buttons\r\
		local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
		local selButton = wx.wxButton(drFrame, wx.wxID_ANY, \"Select\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
		buttonSizer:Add(selButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
		local CancelButton = wx.wxButton(drFrame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
		buttonSizer:Add(CancelButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
		\r\
		\r\
		MainSizer:Add(calSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		drFrame:SetSizer(MainSizer)\r\
		MainSizer:SetSizeHints(drFrame)\r\
	    drFrame:Layout() -- help sizing the windows before being shown\r\
	    drFrame:Show(true)\r\
	    \r\
		selButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			returnFunc(fromDate:GetDate():Format(\"%m/%d/%Y\")..\"-\"..toDate:GetDate():Format(\"%m/%d/%Y\"))\r\
			drFrame:Close()\r\
			objMap[parent] = objMap[parent] - 1\r\
		end	\r\
		)\r\
		CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			drFrame:Close() \r\
			objMap[parent] = objMap[parent] - 1\r\
		end\r\
		)	    	\r\
	end		-- display = function(parent,numInstances,returnFunc) ends\r\
end		-- SelectDateRangeCtrl ends\r\
\r\
-- Date Range Selection Control\r\
do\r\
	local objMap = {}		-- Private Static Variable\r\
	\r\
	local getSelectedItems = function(o)\r\
		local selItems = {}\r\
		local SelList = o.list\r\
		local itemNum = -1\r\
		while SelList:GetNextItem(itemNum) ~= -1 do\r\
			itemNum = SelList:GetNextItem(itemNum)\r\
			local itemText = SelList:GetItemText(itemNum)\r\
			selItems[#selItems + 1] = itemText\r\
		end\r\
		-- Finally Check if none selection box exists\r\
		if o.CheckBox and o.CheckBox:GetValue() then\r\
			selItems[0] = \"true\"\r\
		end\r\
		return selItems\r\
	end\r\
\r\
    local addRange = function(o,range)\r\
		-- Check if the Item exists in the list control\r\
		local itemNum = -1\r\
		local conditionList = false\r\
		while o.list:GetNextItem(itemNum) ~= -1 do\r\
			local prevItemNum = itemNum\r\
			itemNum = o.list:GetNextItem(itemNum)\r\
			local itemText = o.list:GetItemText(itemNum)\r\
			-- Now compare the dateRanges\r\
			local comp = compareDateRanges(range,itemText)\r\
			if comp == 1 then\r\
				-- Ranges are same, do nothing\r\
				drFrame:Close()\r\
				return true\r\
			elseif comp==2 then\r\
				-- range1 lies entirely before range2\r\
				itemNum = prevItemNum\r\
				break\r\
			elseif comp==3 then\r\
				-- comp=3 range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2\r\
				range = combineDateRanges(range,itemText)\r\
				-- Delete the current item\r\
				o.list:DeleteItem(itemNum)\r\
				itemNum = prevItemNum\r\
				break\r\
			elseif comp==4 then\r\
				-- comp=4 range1 lies entirely inside range2\r\
				-- range given is subset, do nothing\r\
				return true\r\
			elseif comp==5 or comp==7 then\r\
				-- comp=5 range1 post overlaps range2\r\
				-- comp=7 range2 lies entirely inside range1\r\
				range = combineDateRanges(range,itemText)\r\
				-- Delete the current item\r\
				o.list:DeleteItem(itemNum)\r\
				itemNum = prevItemNum\r\
				conditionList = true	-- To condition the list to merge any overlapping ranges\r\
				break\r\
			elseif comp==6 then\r\
				-- range1 lies entirely after range2\r\
				-- Do nothing look at next item\r\
			else\r\
				return nil\r\
			end\r\
			--print(range..\">\"..tostring(comp))\r\
		end\r\
		-- itemNum contains the item after which to place item\r\
		if itemNum == -1 then\r\
			itemNum = 0\r\
		else \r\
			itemNum = itemNum + 1\r\
		end\r\
		local newItem = wx.wxListItem()\r\
		newItem:SetId(itemNum)\r\
		newItem:SetText(range)\r\
		o.list:InsertItem(newItem)\r\
		o.list:SetItem(itemNum,0,range)\r\
		\r\
		-- Condition the list here if required\r\
		while conditionList and o.list:GetNextItem(itemNum) ~= -1 do\r\
			local prevItemNum = itemNum\r\
			itemNum = o.list:GetNextItem(itemNum)\r\
			local itemText = o.list:GetItemText(itemNum)\r\
			-- Now compare the dateRanges\r\
			local comp = compareDateRanges(range,itemText)\r\
			if comp == 1 then\r\
				-- Ranges are same, delete this itemText range\r\
				o.list:DeleteItem(itemNum)\r\
				itemNum = prevItemNum\r\
			elseif comp==2 then\r\
				 -- range1 lies entirely before range2\r\
				 conditionList = nil\r\
			elseif comp==3 then\r\
				-- comp=3 range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2\r\
				range = combineDateRanges(range,itemText)\r\
				-- Delete the current item\r\
				o.list:DeleteItem(itemNum)\r\
				itemNum = prevItemNum\r\
				o.list:SetItemText(itemNum,range)\r\
				conditionList = nil\r\
			elseif comp==4 then\r\
				-- comp=4 range1 lies entirely inside range2\r\
				error(\"Code Error: This condition should never occur!\",1)\r\
			elseif comp==5 or comp==7 then\r\
				-- comp=5 range1 post overlaps range2\r\
				-- comp=7 range2 lies entirely inside range1\r\
				range = combineDateRanges(range,itemText)\r\
				-- Delete the current item\r\
				o.list:DeleteItem(itemNum)\r\
				itemNum = prevItemNum\r\
				o.list:SetItemText(itemNum,range)\r\
			elseif comp==6 then\r\
				-- range1 lies entirely after range2\r\
				error(\"Code Error: This condition should never occur!\",1)\r\
			else\r\
				error(\"Code Error: This condition should never occur!\",1)\r\
			end				\r\
		end		-- while conditionList and o.list:GetNextItem(itemNum) ~= -1 ends\r\
		o.list:SetColumnWidth(0,wx.wxLIST_AUTOSIZE)\r\
    end		-- local addRange = function(range) ends\r\
	\r\
	local validateRange = function(range)\r\
		-- Check if the given date range is valid\r\
		-- Expected format is MM/DD/YYYY-MM/DD/YYYY here M and D can be single digits as well\r\
		local _, _, im, id, iy, fm, fd, fy = string.find(range, \"(%d+)/(%d+)/(%d%d%d%d+)%s*-%s*(%d+)/(%d+)/(%d%d%d%d+)\")\r\
		id = tonumber(id)\r\
		im = tonumber(im)\r\
		iy = tonumber(iy)\r\
		fd = tonumber(fd)\r\
		fm = tonumber(fm)\r\
		fy = tonumber(fy)\r\
		local ileap, fleap\r\
		if not(id or im or iy or fd or fm or fy) then\r\
			return false\r\
		elseif not(id > 0 and id < 32 and fd > 0 and fd < 32 and im > 0 and im < 13 and fm > 0 and fm < 13 and iy > 0 and fy > 0) then\r\
			return false\r\
		end\r\
		if fy < iy then\r\
			return false\r\
		end\r\
		if iy == fy then\r\
			if fm < im then\r\
				return false\r\
			end\r\
			if im == fm then\r\
				if fd < id then\r\
					return false\r\
				end\r\
			end\r\
		end \r\
		if iy%100 == 0 and iy%400==0 then\r\
			-- iy is leap year century\r\
			ileap = true\r\
		elseif iy%4 == 0 then\r\
			-- iy is leap year\r\
			ileap = true\r\
		end\r\
		if fy%100 == 0 and fy%400==0 then\r\
			-- fy is leap year century\r\
			fleap = true\r\
		elseif fy%4 == 0 then\r\
			-- fy is leap year\r\
			fleap = true\r\
		end \r\
		--print(id,im,iy,fd,fm,fy,ileap,fleap)\r\
		local validDate = function(leap,date,month)\r\
			local limits = {31,28,31,30,31,30,31,31,30,31,30,31}\r\
			if leap then\r\
				limits[2] = limits[2] + 1\r\
			end\r\
			if limits[month] < date then\r\
				return false\r\
			else\r\
				return true\r\
			end\r\
		end\r\
		if not validDate(ileap,id,im) then\r\
			return false\r\
		end\r\
		if not validDate(fleap,fd,fm) then\r\
			return false\r\
		end\r\
		return true\r\
	end\r\
	\r\
	local setRanges = function(o,ranges)\r\
		for i = 1,#ranges do\r\
			if validateRange(ranges[i]) then\r\
				addRange(o,ranges[i])\r\
			else\r\
				error(\"Invalid Date Range given\", 2)\r\
			end\r\
		end\r\
	end\r\
	\r\
	local setCheckBoxState = function(o,state)\r\
		o.CheckBox:SetValue(state)\r\
	end\r\
	\r\
	local AddPress = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local o = objMap[event:GetId()]\r\
		\r\
		local addNewRange = function(range)\r\
			addRange(o,range)\r\
		end\r\
		\r\
		-- Create the frame to accept date range\r\
		SelectDateRangeCtrl(o.parent,1,addNewRange)\r\
	end\r\
	\r\
	local RemovePress = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local o = objMap[event:GetId()]\r\
		local item = o.list:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
		local selItems = {}\r\
		while item ~= -1 do\r\
			selItems[#selItems + 1] = item	\r\
			item = o.list:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
		end\r\
		for i=#selItems,1,-1 do\r\
			o.list:DeleteItem(selItems[i])\r\
		end\r\
	end\r\
	\r\
	local ClearPress = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local o = objMap[event:GetId()]\r\
		o.list:DeleteAllItems()	\r\
	end\r\
	\r\
	local ResetCtrl = function(o)\r\
		o.list:DeleteAllItems()\r\
		if o.CheckBox then\r\
			o.CheckBox:SetValue(false)\r\
		end\r\
	end\r\
	\r\
	local ListSel = function(event)\r\
		setfenv(1,package.loaded[modname])\r\
		local o = objMap[event:GetId()]\r\
        if o.list:GetSelectedItemCount() == 0 then\r\
			o.RemoveButton:Disable()\r\
        	return nil\r\
        end\r\
		o.RemoveButton:Enable(true)\r\
	end\r\
	\r\
	DateRangeCtrl = function(parent, noneSelection, heading)\r\
		-- parent is a wxPanel\r\
		if not parent then\r\
			return nil\r\
		end\r\
		local o = {ResetCtrl = ResetCtrl, getSelectedItems = getSelectedItems, setRanges = setRanges}	-- new object\r\
		o.parent = parent\r\
		-- Create the GUI elements here\r\
		o.Sizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
		\r\
		-- Heading\r\
		local label = wx.wxStaticText(parent, wx.wxID_ANY, heading, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
		o.Sizer:Add(label, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		\r\
		-- List Control\r\
		local ID\r\
		ID = NewID()\r\
		o.list = wx.wxListCtrl(parent, ID, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\r\
		o.list:InsertColumn(0,\"Ranges\")\r\
		objMap[ID] = o \r\
		o.list:InsertColumn(0,heading)\r\
		o.Sizer:Add(o.list, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		\r\
		-- none Selection check box\r\
		if noneSelection then\r\
			o.setCheckBoxState = setCheckBoxState\r\
			ID = NewID()\r\
			o.CheckBox = wx.wxCheckBox(parent, ID, \"None Also passes\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
			objMap[ID] = o \r\
			o.Sizer:Add(o.CheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
		end\r\
		\r\
		-- Add Date Range Button\r\
		ID = NewID()\r\
		o.AddButton = wx.wxButton(parent, ID, \"Add Range\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
		o.Sizer:Add(o.AddButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
		objMap[ID] = o \r\
\r\
		-- Remove Date Range Button\r\
		ID = NewID()\r\
		o.RemoveButton = wx.wxButton(parent, ID, \"Remove Range\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
		o.Sizer:Add(o.RemoveButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
		objMap[ID] = o \r\
		o.RemoveButton:Disable()\r\
		\r\
		-- Clear Date Ranges Button\r\
		ID = NewID()\r\
		o.ClearButton = wx.wxButton(parent, ID, \"Clear Ranges\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
		o.Sizer:Add(o.ClearButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
		objMap[ID] = o \r\
		\r\
		-- Associate Events\r\
		o.AddButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,AddPress)\r\
		o.RemoveButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,RemovePress)\r\
		o.ClearButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,ClearPress)\r\
\r\
		o.list:Connect(wx.wxEVT_COMMAND_LIST_ITEM_SELECTED,ListSel)\r\
		o.list:Connect(wx.wxEVT_COMMAND_LIST_ITEM_DESELECTED,ListSel)\r\
		\r\
		return o\r\
	end\r\
	\r\
end		-- DateRangeCtrl ends"
__MANY2ONEFILES['TaskForm']="local requireLuaString = requireLuaString\
-----------------------------------------------------------------------------\r\
-- Application: Karm\r\
-- Purpose:     Karm application Task Entry form UI creation and handling file\r\
-- Author:      Milind Gupta\r\
-- Created:     4/11/2012\r\
-----------------------------------------------------------------------------\r\
\r\
local prin\r\
if Karm.Globals.__DEBUG then\r\
	prin = print\r\
end\r\
local error = error\r\
local tonumber = tonumber\r\
local tostring = tostring\r\
local print = prin \r\
local modname = ...\r\
local wx = wx\r\
local wxaui = wxaui\r\
local setfenv = setfenv\r\
local pairs = pairs\r\
local GUI = Karm.GUI\r\
local bit = bit\r\
local Globals = Karm.Globals\r\
local XMLDate2wxDateTime = Karm.Utility.XMLDate2wxDateTime\r\
local toXMLDate = Karm.Utility.toXMLDate\r\
local task2IncSchTasks = Karm.TaskObject.incSchTasks\r\
local getLatestScheduleDates = Karm.TaskObject.getLatestScheduleDates\r\
local getWorkDoneDates = Karm.TaskObject.getWorkDoneDates\r\
local tableToString = Karm.Utility.tableToString\r\
local getEmptyTask = Karm.getEmptyTask\r\
local copyTask = Karm.TaskObject.copy\r\
local collectFilterDataHier = Karm.accumulateTaskDataHier\r\
local togglePlanningDate = Karm.TaskObject.togglePlanningDate\r\
local type = type\r\
local checkTask = function() \r\
					return checkTask\r\
				end\r\
local SData = function()\r\
		return Karm.SporeData\r\
	end\r\
\r\
local CW = requireLuaString('CustomWidgets')\r\
\r\
\r\
module(modname)\r\
\r\
local taskData	-- To store the task data locally\r\
local filterData = {}\r\
\r\
local function dateRangeChangeEvent(event)\r\
	setfenv(1,package.loaded[modname])\r\
	local startDate = dateStartPick:GetValue()\r\
	local finDate = dateFinPick:GetValue()\r\
	taskTree:dateRangeChange(startDate,finDate)\r\
	wdTaskTree:dateRangeChange(startDate,finDate)\r\
	event:Skip()\r\
end\r\
\r\
local function dateRangeChange()\r\
	local startDate = dateStartPick:GetValue()\r\
	local finDate = dateFinPick:GetValue()\r\
	taskTree:dateRangeChange(startDate,finDate)\r\
	wdTaskTree:dateRangeChange(startDate,finDate)\r\
end\r\
\r\
-- Function to create the task\r\
-- If task is not nil then the previous schedules from that are copied over by starting with a copy of the task\r\
local function makeTask(task)\r\
	if not task then\r\
		error(\"Need a task object with at least a task ID\",2)\r\
	end\r\
	local newTask = copyTask(task)\r\
--	if task then\r\
--		-- Since copyTask does not replicate that\r\
--		newTask.DBDATA = task.DBDATA\r\
--	end\r\
	newTask.Modified = true\r\
	if pubPrivate:GetValue() == \"Public\" then\r\
		newTask.Private = false\r\
	else\r\
		newTask.Private = true\r\
	end \r\
	newTask.Title = titleBox:GetValue()\r\
	if newTask.Title == \"\" then\r\
		wx.wxMessageBox(\"The task Title cannot be blank. Please enter a title\", \"No Title Entered\",wx.wxOK + wx.wxCENTRE, frame)\r\
	    return nil\r\
	end\r\
	newTask.Start = toXMLDate(dateStarted:GetValue():Format(\"%m/%d/%Y\"))\r\
	-- newTask.TaskID = task.TaskID -- Already has task ID from copyTask\r\
	-- Status\r\
	newTask.Status = status:GetValue()\r\
	-- Fin\r\
	local todayDate = wx.wxDateTime()\r\
	todayDate:SetToCurrent()\r\
	todayDate = toXMLDate(todayDate:Format(\"%m/%d/%Y\"))\r\
	if task and task.Status ~= \"Done\" and newTask.Status == \"Done\" then\r\
		newTask.Fin = todayDate\r\
	elseif newTask.Status ~= \"Done\" then\r\
		newTask.Fin = nil\r\
	end\r\
	if priority:GetValue() ~= \"\" then\r\
		newTask.Priority = priority:GetValue()\r\
	else\r\
		newTask.Priority = nil\r\
	end\r\
	if DueDateEN:GetValue() then\r\
		newTask.Due = toXMLDate(dueDate:GetValue():Format(\"%m/%d/%Y\"))\r\
	else\r\
		newTask.Due = nil\r\
	end\r\
	-- Who List\r\
	local list = whoList:getAllItems()\r\
	if list[1] then\r\
		local WhoTable = {[0]=\"Who\", count = #list}\r\
		-- Loop through all the items in the list\r\
		for i = 1,#list do\r\
			WhoTable[i] = {ID = list[i].itemText, Status = list[i].checked}\r\
		end\r\
		newTask.Who = WhoTable\r\
	else\r\
		wx.wxMessageBox(\"The task should be assigned to someone. It cannot be blank. Please choose the people responsible.\", \"Task not assigned\",wx.wxOK + wx.wxCENTRE, frame)\r\
	    return nil\r\
	end\r\
	-- Access List\r\
	list = accList:getAllItems()\r\
	if list[1] then\r\
		local AccTable = {[0]=\"Access\", count = #list}\r\
		-- Loop through all the items in the Locked element Access List\r\
		for i = 1,#list do\r\
			AccTable[i] = {ID = list[i].itemText, Status = list[i].checked}\r\
		end\r\
		newTask.Access = AccTable\r\
	else\r\
		newTask.Access = nil\r\
	end		\r\
	-- Assignee List\r\
	list = {}\r\
	local itemNum = -1\r\
	while assigList:GetNextItem(itemNum) ~= -1 do\r\
		itemNum = assigList:GetNextItem(itemNum)\r\
		local itemText = assigList:GetItemText(itemNum)\r\
		list[#list + 1] = itemText\r\
	end\r\
	if list[1] then\r\
		local assignee = {[0]=\"Assignee\", count = #list}\r\
		-- Loop through all the items in the Assignee List\r\
		for i = 1,#list do\r\
			assignee[i] = {ID = list[i]}\r\
		end				\r\
		newTask.Assignee = assignee					\r\
	else\r\
		newTask.Assignee = nil\r\
	end		\r\
	-- Comments\r\
	if commentBox:GetValue() ~= \"\" then\r\
		newTask.Comments = commentBox:GetValue()\r\
	else \r\
		newTask.Comments = nil\r\
	end\r\
	-- Category\r\
	if Category:GetValue() ~= \"\" then\r\
		newTask.Cat = Category:GetValue()\r\
	else\r\
		newTask.Cat = nil\r\
	end\r\
	--SubCategory\r\
	if SubCategory:GetValue() ~= \"\" then \r\
		newTask.SubCat = SubCategory:GetValue()\r\
	else\r\
		newTask.SubCat = nil\r\
	end\r\
	-- Tags\r\
	list = TagsCtrl:getSelectedItems()\r\
	if list[1] then\r\
		local tagTable = {[0]=\"Tags\", count = #list}\r\
		-- Loop through all the items in the Tags element\r\
		for i = 1,#list do\r\
			tagTable[i] = list[i]\r\
		end\r\
		newTask.Tags = tagTable\r\
	else\r\
		newTask.Tags = nil\r\
	end		\r\
	-- Normal Schedule\r\
	if HoldPlanning:GetValue() then\r\
		newTask.Planning = taskTree.taskList[1].Planning\r\
	else\r\
		list = getLatestScheduleDates(taskTree.taskList[1],true)\r\
		if list then\r\
			local list1 = getLatestScheduleDates(newTask)\r\
			-- Compare the schedules\r\
			local same = true\r\
			if not list1 or #list1 ~= #list or (list1.typeSchedule ~= list.typeSchedule and \r\
			  not(list1.typeSchedule==\"Commit\" and list.typeSchedule == \"Revs\")) then\r\
				same = false\r\
			else\r\
				for i = 1,#list do\r\
					if list[i] ~= list1[i] then\r\
						same = false\r\
						break\r\
					end\r\
				end\r\
			end\r\
			if not same then\r\
				-- Add the schedule here\r\
				if not newTask.Schedules then\r\
					newTask.Schedules = {}\r\
				end\r\
				if not newTask.Schedules[list.typeSchedule] then\r\
					-- Schedule type does not exist so create it\r\
					newTask.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}\r\
				end\r\
				-- Schedule type already exists so just add it to the next index\r\
				local newSched = {[0]=list.typeSchedule}\r\
				local str = \"WD\"\r\
				if list.typeSchedule ~= \"Actual\" then\r\
					if schCommentBox:GetValue() ~= \"\" then\r\
						newSched.Comment = schCommentBox:GetValue()\r\
					end\r\
					newSched.Updated = todayDate\r\
					str = \"DP\"\r\
				else\r\
					error(\"Got Actual schedule type while processing schedule.\")\r\
				end\r\
				-- Update the period\r\
				newSched.Period = {[0] = \"Period\", count = #list}\r\
				for i = 1,#list do\r\
					newSched.Period[i] = {[0] = str, Date = list[i]}\r\
				end\r\
				newTask.Schedules[list.typeSchedule][list.index] = newSched\r\
				newTask.Schedules[list.typeSchedule].count = list.index\r\
			end\r\
		end		-- if list ends here\r\
		newTask.Planning = nil\r\
	end		-- if HoldPlanning.GetValue() then ends\r\
	-- Work done Schedule\r\
	list = getLatestScheduleDates(wdTaskTree.taskList[1],true)\r\
	if list then\r\
		local list1 = getWorkDoneDates(newTask)\r\
		-- Compare the schedules\r\
		local same = true\r\
		if not list1 or #list1 ~= #list then\r\
			same = false\r\
		else\r\
			for i = 1,#list do\r\
				if list[i] ~= list1[i] then\r\
					same = false\r\
					break\r\
				end\r\
			end\r\
		end\r\
		if not same then\r\
			-- Add the schedule here\r\
			if not newTask.Schedules then\r\
				newTask.Schedules = {}\r\
			end\r\
			if not newTask.Schedules[list.typeSchedule] then\r\
				-- Schedule type does not exist so create it\r\
				newTask.Schedules[list.typeSchedule] = {[0]=list.typeSchedule}\r\
			end\r\
			-- Schedule type already exists so just add it to the next index\r\
			local newSched = {[0]=list.typeSchedule, Updated = todayDate}\r\
			local str = \"WD\"\r\
			-- Update the period\r\
			newSched.Period = {[0] = \"Period\", count = #list}\r\
			for i = 1,#list do\r\
				newSched.Period[i] = wdTaskTree.taskList[1].Planning.Period[i]\r\
			end\r\
			newTask.Schedules[list.typeSchedule][list.index] = newSched\r\
			newTask.Schedules[list.typeSchedule].count = list.index\r\
		end\r\
	end		-- if list ends here\r\
--	print(tableToString(list))\r\
--	print(tableToString(newTask))\r\
	local chkTask = checkTask()\r\
	if type(chkTask) == \"function\" then\r\
		local err,msg = chkTask(newTask)\r\
		if not err then\r\
			msg = msg or \"Error in the task. Please review.\"\r\
			wx.wxMessageBox(msg, \"Task Error\",wx.wxOK + wx.wxCENTRE, frame)\r\
			return nil\r\
		end\r\
	end\r\
	return newTask\r\
end\r\
\r\
function taskFormActivate(parent, callBack, task)\r\
	local SporeData = SData()\r\
	-- Accumulate Filter Data across all spores\r\
	-- Loop through all the spores\r\
	for k,v in pairs(SporeData) do\r\
		if k~=0 then\r\
			collectFilterDataHier(filterData,v)\r\
		end		-- if k~=0 then ends\r\
	end		-- for k,v in pairs(SporeData) do ends\r\
	frame = wx.wxFrame(parent, wx.wxID_ANY, \"Task Form\", wx.wxDefaultPosition,\r\
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)\r\
\r\
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
		-- Create the tab book\r\
		MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)\r\
		-- Basic Task Info\r\
		TInfo = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				local sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
				local textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Title:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				if task and task.Title then\r\
					titleBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, task.Title, wx.wxDefaultPosition, wx.wxDefaultSize)\r\
				else\r\
					titleBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize)\r\
				end				\r\
				sizer2:Add(titleBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					-- Start Date\r\
					local sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Start Date:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					if task and task.Start then\r\
						dateStarted = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,XMLDate2wxDateTime(task.Start), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\r\
					else\r\
						dateStarted = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\r\
					end					\r\
					sizer3:Add(dateStarted, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
					-- Due Date\r\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Due Date:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					local sizer4 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					DueDateEN = wx.wxCheckBox(TInfo, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
					DueDateEN:SetValue(false)\r\
					sizer4:Add(DueDateEN, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
					if task and task.Due then\r\
						dueDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,XMLDate2wxDateTime(task.Due), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\r\
					else\r\
						dueDate = wx.wxDatePickerCtrl(TInfo, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\r\
					end	\r\
					-- dueDate:SetRange(XMLDate2wxDateTime(\"1900-01-01\"),XMLDate2wxDateTime(\"3000-01-01\"))					\r\
					sizer4:Add(dueDate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					sizer3:Add(sizer4,1,bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
					-- Priority\r\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Priority:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					local list = {\"\"}\r\
					for i = 1,#Globals.PriorityList do\r\
						list[i+1] = Globals.PriorityList[i]\r\
					end\r\
					if task and task.Priority then\r\
						priority = wx.wxComboBox(TInfo, wx.wxID_ANY,task.Priority, wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)\r\
					else\r\
						priority = wx.wxComboBox(TInfo, wx.wxID_ANY,\"\", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)\r\
					end\r\
					sizer3:Add(priority, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
\r\
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
\r\
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					-- Private/Public\r\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Private/Public:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					list = {\"Public\",\"Private\"}\r\
					if task and task.Private then\r\
						pubPrivate = wx.wxComboBox(TInfo, wx.wxID_ANY,\"Private\", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)\r\
					else\r\
						pubPrivate = wx.wxComboBox(TInfo, wx.wxID_ANY,\"Public\", wx.wxDefaultPosition, wx.wxDefaultSize,list, wx.wxCB_READONLY)\r\
					end\r\
					sizer3:Add(pubPrivate, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
					-- Status\r\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Status:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					if task and task.Status then\r\
						status = wx.wxComboBox(TInfo, wx.wxID_ANY,task.Status, wx.wxDefaultPosition, wx.wxDefaultSize, Globals.StatusList, wx.wxCB_READONLY)\r\
					else\r\
						status = wx.wxComboBox(TInfo, wx.wxID_ANY,Globals.StatusList[1], wx.wxDefaultPosition, wx.wxDefaultSize, Globals.StatusList, wx.wxCB_READONLY)\r\
					end					\r\
					sizer3:Add(status, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
					sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
				-- Comment\r\
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				textLabel = wx.wxStaticText(TInfo, wx.wxID_ANY, \"Comment:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\r\
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				if task and task.Comments then\r\
					commentBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, task.Comments, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)\r\
				else\r\
					commentBox = wx.wxTextCtrl(TInfo, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)\r\
				end\r\
				sizer2:Add(commentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
\r\
				\r\
				TInfo:SetSizer(sizer1)\r\
			sizer1:SetSizeHints(TInfo)\r\
		MainBook:AddPage(TInfo, \"Basic Info\")				\r\
\r\
		-- Classification Page\r\
		TClass = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
\r\
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, \"Category:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					list = {\"\"}\r\
					for i = 1,#Globals.Categories do\r\
						list[i+1] = Globals.Categories[i]\r\
					end\r\
					if task and task.Cat then\r\
						Category = wx.wxComboBox(TClass, wx.wxID_ANY,task.Cat, wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)\r\
					else\r\
						Category = wx.wxComboBox(TClass, wx.wxID_ANY,list[1], wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)\r\
					end					\r\
					sizer3:Add(Category, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, \"Sub-Category:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					sizer3:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					list = {\"\"}\r\
					for i = 1,#Globals.SubCategories do\r\
						list[i+1] = Globals.SubCategories[i]\r\
					end\r\
					if task and task.SubCat then\r\
						SubCategory = wx.wxComboBox(TClass, wx.wxID_ANY,task.SubCat, wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)\r\
					else\r\
						SubCategory = wx.wxComboBox(TClass, wx.wxID_ANY,list[1], wx.wxDefaultPosition, wx.wxDefaultSize, list, wx.wxCB_READONLY)\r\
					end					\r\
					sizer3:Add(SubCategory, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
\r\
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
\r\
				textLabel = wx.wxStaticText(TClass, wx.wxID_ANY, \"Tags:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\r\
				sizer1:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				TagsCtrl = CW.MultiSelectCtrl(TClass,filterData.Tags,nil,false,true)\r\
				if task and task.Tags then\r\
					TagsCtrl:AddSelListData(task.Tags)\r\
				end\r\
				sizer1:Add(TagsCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
				TClass:SetSizer(sizer1)\r\
			sizer1:SetSizeHints(TClass)\r\
		MainBook:AddPage(TClass, \"Classification\")				\r\
\r\
		-- People Page\r\
		TPeople = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				-- Resources\r\
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, \"People:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\r\
				sizer2:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				resourceList = wx.wxListCtrl(TPeople, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\r\
				resourceList:InsertColumn(0,\"Options\")\r\
				-- Populate the resources\r\
				if not Globals.Resources or #Globals.Resources == 0 then\r\
					wx.wxMessageBox(\"There are no people in the Globals.Resources setting. Please add a list of people to which task can be assigned\", \"No People found\",wx.wxOK + wx.wxCENTRE, frame) \r\
					frame:Close()\r\
					callBack(nil)\r\
					return\r\
				end\r\
				\r\
				for i = 1,#Globals.Resources do\r\
					CW.InsertItem(resourceList,Globals.Resources[i])\r\
				end\r\
				CW.InsertItem(resourceList,Globals.User)\r\
				sizer2:Add(resourceList, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				-- Selection boxes and buttons\r\
				sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				AddWhoButton = wx.wxButton(TPeople, wx.wxID_ANY, \">\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				sizer4:Add(AddWhoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				RemoveWhoButton = wx.wxButton(TPeople, wx.wxID_ANY, \"X\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				sizer4:Add(RemoveWhoButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, \"Who: (Checked=InActive)\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\r\
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				whoList = CW.CheckListCtrl(TPeople,false,\"Inactive\",\"Active\")\r\
				if task and task.Who then\r\
					for i = 1,#task.Who do\r\
						local id = task.Who[i].ID\r\
						if task.Who[i].Status == \"Active\" then\r\
							whoList:InsertItem(id)\r\
						else\r\
							whoList:InsertItem(id,true)\r\
						end\r\
					end\r\
				end\r\
				sizer4:Add(whoList.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				AddAccButton = wx.wxButton(TPeople, wx.wxID_ANY, \">\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				sizer4:Add(AddAccButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				RemoveAccButton = wx.wxButton(TPeople, wx.wxID_ANY, \"X\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				sizer4:Add(RemoveAccButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, \"Access: (Checked=Read/Write)\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\r\
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				accList = CW.CheckListCtrl(TPeople,false,\"Read/Write\",\"Read Only\")\r\
				if task and task.Access then\r\
					for i = 1,#task.Access do\r\
						local id = task.Access[i].ID\r\
						if task.Access[i].Status == \"Read/Write\" then\r\
							accList:InsertItem(id,true)\r\
						else\r\
							accList:InsertItem(id)\r\
						end\r\
					end\r\
				end				\r\
				sizer4:Add(accList.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
\r\
				sizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				AddAssigButton = wx.wxButton(TPeople, wx.wxID_ANY, \">\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				sizer4:Add(AddAssigButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				RemoveAssigButton = wx.wxButton(TPeople, wx.wxID_ANY, \"X\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				sizer4:Add(RemoveAssigButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				textLabel = wx.wxStaticText(TPeople, wx.wxID_ANY, \"Assignee:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTER)\r\
				sizer4:Add(textLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				assigList = wx.wxListCtrl(TPeople, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxLC_REPORT+wx.wxLC_NO_HEADER)\r\
				assigList:InsertColumn(0,\"Assignees\")\r\
				if task and task.Assignee then\r\
					for i = 1,#task.Assignee do\r\
						CW.InsertItem(assigList,task.Assignee[i].ID)\r\
					end\r\
				end\r\
				sizer4:Add(assigList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer3:Add(sizer4, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer2:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
				sizer1:Add(sizer2, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
				TPeople:SetSizer(sizer1)\r\
			sizer1:SetSizeHints(TPeople)\r\
		MainBook:AddPage(TPeople, \"People\")				\r\
\r\
		-- Schedule Page\r\
		TSch = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					dateStartPick = wx.wxDatePickerCtrl(TSch, wx.wxID_ANY,wx.wxDefaultDateTime, wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\r\
					startDate = dateStartPick:GetValue()\r\
					local month = wx.wxDateSpan(0,1,0,0)\r\
					dateFinPick = wx.wxDatePickerCtrl(TSch, wx.wxID_ANY,startDate:Add(month), wx.wxDefaultPosition, wx.wxDefaultSize,wx.wxDP_DROPDOWN)\r\
					sizer2:Add(dateStartPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, wx.wxALIGN_CENTER_VERTICAL), 1)\r\
					sizer2:Add(dateFinPick,1, bit.bor(wx.wxALL, wx.wxEXPAND, wx.wxALIGN_CENTER_HORIZONTAL, 	wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer1:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				local staticBoxSizer = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, TSch, \"Work Done\")\r\
					wdTaskTree = GUI.newTreeGantt(TSch,true)\r\
					sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					sizer3:Add(wdTaskTree.horSplitWin, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
					sizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					sizer4 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					local wdDateLabel = wx.wxStaticText(TSch, wx.wxID_ANY, \"Date: XX/XX/XXXX\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\r\
					sizer4:Add(wdDateLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					local wdHourLabel = wx.wxStaticText(TSch, wx.wxID_ANY, \"Hours: \", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\r\
					sizer4:Add(wdHourLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					sizer2:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
					local wdCommentLabel = wx.wxStaticText(TSch, wx.wxID_ANY, \"Comment: \", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					sizer2:Add(wdCommentLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					local wdCommentBox = wx.wxTextCtrl(TSch, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE + wx.wxTE_READONLY)\r\
					sizer2:Add(wdCommentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
					sizer3:Add(sizer2, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
					staticBoxSizer:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				sizer1:Add(staticBoxSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
				staticBoxSizer = wx.wxStaticBoxSizer(wx.wxHORIZONTAL, TSch, \"Schedules\")\r\
				sizer3 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				\r\
				taskTree = GUI.newTreeGantt(TSch,true)\r\
				sizer3:Add(taskTree.horSplitWin, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				dateRangeChange()\r\
				taskTree:layout()\r\
				wdTaskTree:layout()\r\
				local localTask1, localTask2\r\
				if not task.Title then\r\
					localTask1 = getEmptyTask()\r\
					localTask2 = getEmptyTask()\r\
				else\r\
					localTask1 = copyTask(task)\r\
					localTask2 = copyTask(task)\r\
				end\r\
				-- Create the 1st row for the task\r\
				localTask1.Planning = nil	-- Since we will use this task for Work Done Entry and Work done never maintains the Planning\r\
			    wdTaskTree:Clear()\r\
			    wdTaskTree:AddNode{Key=localTask1.TaskID, Text = localTask1.Title, Task = localTask1}\r\
			    wdTaskTree.Nodes[localTask1.TaskID].ForeColor = GUI.nodeForeColor\r\
			    taskTree:Clear()\r\
			    taskTree:AddNode{Key=localTask2.TaskID, Text = localTask2.Title, Task = localTask2}\r\
			    taskTree.Nodes[localTask2.TaskID].ForeColor = GUI.nodeForeColor\r\
			    local prevKey = localTask1.TaskID\r\
				-- Get list of mock tasks with incremental schedule\r\
				if task and task.Schedules then\r\
					local taskList = task2IncSchTasks(task)\r\
					-- Now add these tasks\r\
					for i = 1,#taskList do\r\
						taskList[i].Planning = nil	-- To make sure that a task already having Planning does not propagate that in successive schedules\r\
		            	taskTree:AddNode{Relative=prevKey, Relation=\"Next Sibling\", Key=taskList[i].TaskID, Text=taskList[i].Title, Task = taskList[i]}\r\
		            	taskTree.Nodes[taskList[i].TaskID].ForeColor = GUI.nodeForeColor\r\
		            	prevKey = taskList[i].TaskID\r\
		            end\r\
				end\r\
				-- Enable planning mode for the task\r\
				taskTree:enablePlanningMode({localTask2},\"NORMAL\")\r\
				wdTaskTree:enablePlanningMode({localTask1},\"WORKDONE\")\r\
				-- Add the comment box\r\
				sizer4 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
				textLabel = wx.wxStaticText(TSch, wx.wxID_ANY, \"Comment:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\r\
				sizer4:Add(textLabel, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				HoldPlanning = wx.wxCheckBox(TSch, wx.wxID_ANY, \"Hold Planning\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				HoldPlanning:SetValue(false)\r\
				sizer4:Add(HoldPlanning, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				sizer3:Add(sizer4, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				schCommentBox = wx.wxTextCtrl(TSch, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize)\r\
				sizer3:Add(schCommentBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
				staticBoxSizer:Add(sizer3, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				sizer1:Add(staticBoxSizer, 2, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL), 1)\r\
				\r\
				TSch:SetSizer(sizer1)\r\
			sizer1:SetSizeHints(TSch)\r\
		MainBook:AddPage(TSch, \"Schedules\")	\r\
		\r\
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	sizer1 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
	CancelButton = wx.wxButton(frame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
	sizer1:Add(CancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	DoneButton = wx.wxButton(frame, wx.wxID_ANY, \"Done\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
	sizer1:Add(DoneButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	MainSizer:Add(sizer1, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
	frame:SetSizer(MainSizer)\r\
\r\
	-- Event handler for the Work Done elements\r\
	local workDoneHourCommentEntry = function(task,row,col,date)\r\
		-- First check whether the date is in the schedule\r\
		local exist = false\r\
		local prevHours, prevComment\r\
		if localTask1.Planning then\r\
			for i = 1,#localTask1.Planning.Period do\r\
				if date == localTask1.Planning.Period[i].Date then\r\
					prevHours = localTask1.Planning.Period[i].Hours or \"\"\r\
					prevComment = localTask1.Planning.Period[i].Comment or \"\"\r\
					exist = true\r\
					break\r\
				end\r\
			end\r\
		end\r\
		if exist then\r\
			local wdFrame = wx.wxFrame(frame, wx.wxID_ANY, \"Work Done Details for date \"..date, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxDEFAULT_FRAME_STYLE)\r\
			local wdSizer1 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				-- Data entry UI\r\
				local wdSizer2 = wx.wxBoxSizer(wx.wxVERTICAL)\r\
					local wdSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					wdTextLabel = wx.wxStaticText(wdFrame, wx.wxID_ANY, \"Hours:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\r\
					wdSizer3:Add(wdTextLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					local wdList = {\"1\", \"2\",\"3\",\"4\",\"5\",\"6\",\"7\",\"8\",\"9\",\"10\"}\r\
					local wdHours = wx.wxComboBox(wdFrame, wx.wxID_ANY,prevHours, wx.wxDefaultPosition, wx.wxDefaultSize,wdList)\r\
					wdSizer3:Add(wdHours, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					wdSizer2:Add(wdSizer3, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
					wdSizer3 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					wdTextLabel = wx.wxStaticText(wdFrame, wx.wxID_ANY, \"Comment:\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
					wdSizer3:Add(wdTextLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
					wdSizer2:Add(wdSizer3, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
					local w = 0.5*GUI.initFrameW\r\
					local l = 0.5*GUI.initFrameH\r\
					w = w - w%1\r\
					l = l - l%1\r\
					local wdComment = wx.wxTextCtrl(wdFrame, wx.wxID_ANY, prevComment, wx.wxDefaultPosition, wx.wxSize(w, l), wx.wxTE_MULTILINE)\r\
					wdSizer2:Add(wdComment, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				wdSizer1:Add(wdSizer2, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				-- Buttons\r\
				wdSizer2 = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					local wdCancelButton = wx.wxButton(wdFrame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
					wdSizer2:Add(wdCancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
					local wdDoneButton = wx.wxButton(wdFrame, wx.wxID_ANY, \"Done\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
					wdSizer2:Add(wdDoneButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				wdSizer1:Add(wdSizer2, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			wdFrame:SetSizer(wdSizer1)\r\
			wdSizer1:SetSizeHints(wdFrame)\r\
			wdCancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
				function (event)\r\
					wdFrame:Close()\r\
				end\r\
			)\r\
			wdDoneButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
				function (event)\r\
					setfenv(1,package.loaded[modname])\r\
					local hours = wdHours:GetValue()\r\
					local comment = wdComment:GetValue()\r\
					if tonumber(hours) then\r\
						hours = tostring(tonumber(hours))\r\
					else\r\
						hours = \"\"\r\
					end\r\
					if hours ~= \"\" or comment ~= \"\" then\r\
						-- Add the hours and Comment information to the task here\r\
						for i = 1,#localTask1.Planning.Period do\r\
							if localTask1.Planning.Period[i].Date == date then\r\
								if hours ~= \"\" then\r\
									localTask1.Planning.Period[i].Hours = hours\r\
								end\r\
								if comment ~= \"\" then\r\
									localTask1.Planning.Period[i].Comment = comment\r\
								end\r\
								break\r\
							end\r\
						end\r\
						-- Update the hours and comment box\r\
						wdDateLabel:SetLabel(\"Date: \"..date:sub(-5,-4)..\"/\"..date:sub(-2,-1)..\"/\"..date:sub(1,4))\r\
						wdHourLabel:SetLabel(\"Hours: \"..hours)\r\
						wdCommentBox:SetValue(comment)\r\
					end		-- if hours ~= \"\" or comment ~= \"\" then ends\r\
					wdFrame:Close()\r\
				end\r\
			)\r\
		    wdFrame:Layout() -- help sizing the windows before being shown\r\
		    wdFrame:Show(true)\r\
		end	-- if exist then ends		\r\
	end\r\
	\r\
	local prevDate, wdPlanning\r\
	wdPlanning = {Planning = {Type = \"Actual\", index = 1}}\r\
	\r\
	local function updateHoursComment(task,row,col,date)\r\
		if not prevDate then\r\
			prevDate = date\r\
		end\r\
		-- First check whether the date is in the schedule\r\
		local exist = false\r\
		local existwd = false\r\
		local perNum, wdNum\r\
		if localTask1.Planning then\r\
			for i = 1,#localTask1.Planning.Period do\r\
				if date == localTask1.Planning.Period[i].Date then\r\
					perNum = i\r\
					exist = true\r\
					break\r\
				end\r\
			end\r\
		end\r\
		if wdPlanning.Planning.Period then\r\
			for i = 1,#wdPlanning.Planning.Period do\r\
				if date == wdPlanning.Planning.Period[i].Date then\r\
					wdNum = i\r\
					existwd = true\r\
					break\r\
				end\r\
			end\r\
		end\r\
		\r\
		if exist then\r\
			if not existwd then\r\
				-- Add it to wdPlanning\r\
				if not wdPlanning.Planning.Period then\r\
					wdPlanning.Planning.Period = {}\r\
				end\r\
				wdPlanning.Planning.Period[#wdPlanning.Planning.Period + 1] = localTask1.Planning.Period[perNum]\r\
			end\r\
		else\r\
			if existwd then\r\
				if prevDate ~= date then\r\
					-- Add it back in the task\r\
					togglePlanningDate(localTask1,date,\"WORKDONE\")\r\
					for i = 1,#localTask1.Planning.Period do\r\
						if localTask1.Planning.Period[i].Date == date then\r\
							localTask1.Planning.Period[i].Hours = wdPlanning.Planning.Period[wdNum].Hours\r\
							localTask1.Planning.Period[i].Comment = wdPlanning.Planning.Period[wdNum].Comment\r\
							break\r\
						end\r\
					end\r\
					-- Update GUI\r\
					wdTaskTree:RefreshNode(localTask1)\r\
				else\r\
					-- Remove it from wdPlanning\r\
					for i = wdNum,#wdPlanning.Planning.Period - 1 do\r\
						wdPlanning.Planning.Period[i] = wdPlanning.Planning.Period[i+1]\r\
					end\r\
					wdPlanning.Planning.Period[#wdPlanning.Planning.Period] = nil\r\
				end\r\
			end\r\
		end\r\
		prevDate = date\r\
		local hours, comment\r\
		-- Extract the hours and comments\r\
		if localTask1.Planning then\r\
			for i = 1,#localTask1.Planning.Period do\r\
				if date == localTask1.Planning.Period[i].Date then\r\
					hours = localTask1.Planning.Period[i].Hours\r\
					comment = localTask1.Planning.Period[i].Comment\r\
					break\r\
				end\r\
			end\r\
		end\r\
		-- Update the hours and comment box\r\
		wdDateLabel:SetLabel(\"Date: \"..date:sub(-5,-4)..\"/\"..date:sub(-2,-1)..\"/\"..date:sub(1,4))\r\
		if hours then\r\
			wdHourLabel:SetLabel(\"Hours: \"..hours)\r\
		else\r\
			wdHourLabel:SetLabel(\"Hours: \")\r\
		end\r\
		if comment then\r\
			wdCommentBox:SetValue(comment)\r\
		else\r\
			wdCommentBox:SetValue(\"\")\r\
		end		\r\
	end\r\
	\r\
	wdTaskTree:associateEventFunc({ganttCellDblClickCallBack = workDoneHourCommentEntry, ganttCellClickCallBack = updateHoursComment})\r\
	-- Connect event handlers to the buttons\r\
	RemoveAccButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			local item = accList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
			while item ~= -1 do\r\
				accList.List:DeleteItem(item)			\r\
				item = accList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
			end\r\
		end\r\
	)\r\
\r\
	RemoveAssigButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			local item = assigList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
			while item ~= -1 do\r\
				assigList:DeleteItem(item)			\r\
				item = assigList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
			end\r\
		end\r\
	)\r\
\r\
	RemoveWhoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			local selItems = {}\r\
			local item = whoList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
			while item ~= -1 do\r\
				whoList.List:DeleteItem(item)\r\
				item = whoList.List:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
			end\r\
		end\r\
	)\r\
\r\
	AddAccButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
			while item ~= -1 do\r\
				local itemText = resourceList:GetItemText(item)\r\
				accList:InsertItem(itemText)			\r\
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
			end\r\
		end\r\
	)\r\
	\r\
	AddAssigButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
			while item ~= -1 do\r\
				local itemText = resourceList:GetItemText(item)\r\
				CW.InsertItem(assigList,itemText)		\r\
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
			end\r\
		end\r\
	)\r\
\r\
	AddWhoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			local item = resourceList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
			while item ~= -1 do\r\
				local itemText = resourceList:GetItemText(item)\r\
				whoList:InsertItem(itemText)			\r\
				item = resourceList:GetNextItem(item,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)	\r\
			end\r\
		end\r\
	)\r\
\r\
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function (event)\r\
			setfenv(1,package.loaded[modname])		\r\
			frame:Close()\r\
			callBack(nil)\r\
		end\r\
	)\r\
	\r\
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,\r\
		function (event)\r\
			setfenv(1,package.loaded[modname])		\r\
			event:Skip()\r\
			callBack(nil)\r\
		end\r\
	)\r\
\r\
	DoneButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			local newTask = makeTask(task)\r\
			if newTask then\r\
				callBack(newTask)\r\
				frame:Close()\r\
			end\r\
		end		\r\
	)\r\
	\r\
	DueDateEN:Connect(wx.wxEVT_COMMAND_CHECKBOX_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			if DueDateEN:GetValue() then\r\
				dueDate:Enable(true)\r\
			else\r\
				dueDate:Disable()\r\
			end\r\
		end\r\
	)\r\
	\r\
	-- Date Picker Events\r\
	dateStartPick:Connect(wx.wxEVT_DATE_CHANGED,dateRangeChangeEvent)\r\
	dateFinPick:Connect(wx.wxEVT_DATE_CHANGED,dateRangeChangeEvent)\r\
	\r\
\r\
    frame:Layout() -- help sizing the windows before being shown\r\
    frame:Show(true)\r\
\r\
end	-- function taskFormActivate(parent, callBack)"
__MANY2ONEFILES['Filter']="-- Data structure to store the Global Filter Criteria\r\
Karm.Filter = {}\r\
Karm.FilterObject = {}\r\
\r\
-- Function to create a text summary of the Filter\r\
function Karm.FilterObject.getSummary(filter)\r\
	local filterSummary = \"\"\r\
	-- Tasks\r\
	if filter.Tasks then\r\
		-- Get the task name\r\
		for i=1,#filter.Tasks do\r\
			if i>1 then\r\
				filterSummary = filterSummary..\"\\n\"\r\
			else\r\
				filterSummary = \"TASKS: \"\r\
			end\r\
			filterSummary = filterSummary..filter.Tasks[i].Title\r\
			if filter.Tasks[i].Children then\r\
				filterSummary = filterSummary..\" and Children\"\r\
			end\r\
		end\r\
		filterSummary = filterSummary..\"\\n\"\r\
	end\r\
	-- Who\r\
	if filter.Who then\r\
		filterSummary = filterSummary..\"PEOPLE: \"..filter.Who..\"\\n\"\r\
	end\r\
	-- Start Date\r\
	if filter.Start then\r\
		filterSummary = filterSummary..\"START DATE: \"..filter.Start..\"\\n\"\r\
	end\r\
	-- Finish Date\r\
	if filter.Fin then\r\
		filterSummary = filterSummary..\"FINISH DATE: \"..filter.Fin..\"\\n\"\r\
	end\r\
	-- Access IDs\r\
	if filter.Access then\r\
		filterSummary = filterSummary..\"ACCESS: \"..filter.Access..\"\\n\"\r\
	end\r\
	-- Status\r\
	if filter.Status then\r\
		filterSummary = filterSummary..\"STATUS: \"..filter.Status..\"\\n\"\r\
	end\r\
	-- Priority\r\
	if filter.Priority then\r\
		filterSummary = filterSummary..\"PRIORITY: \"..filter.Priority..\"\\n\"\r\
	end\r\
	-- Due Date\r\
	if filter.Due then\r\
		filterSummary = filterSummary..\"DUE DATE: \"..filter.Due..\"\\n\"\r\
	end\r\
	-- Category\r\
	if filter.Cat then\r\
		filterSummary = filterSummary..\"CATEGORY: \"..filter.Cat..\"\\n\"\r\
	end\r\
	-- Sub-Category\r\
	if filter.SubCat then\r\
		filterSummary = filterSummary..\"SUB-CATEGORY: \"..filter.SubCat..\"\\n\"\r\
	end\r\
	-- Tags\r\
	if filter.Tags then\r\
		filterSummary = filterSummary..\"TAGS: \"..filter.Tags..\"\\n\"\r\
	end\r\
	-- Schedules\r\
	if filter.Schedules then\r\
		filterSummary = filterSummary..\"SCHEDULES: \"..filter.Schedules..\"\\n\"\r\
	end\r\
	if filter.Script then\r\
		filterSummary = filterSummary..\"CUSTOM SCRIPT APPLIED\"..\"\\n\"\r\
	end\r\
	if filterSummary == \"\" then\r\
		filterSummary = \"No Filtering\"\r\
	end\r\
	return filterSummary\r\
end\r\
\r\
-- Function to filter out tasks from the task hierarchy\r\
function Karm.FilterObject.applyFilterHier(filter, taskHier)\r\
	local hier = taskHier\r\
	local returnList = {count = 0}\r\
	local data = {returnList = returnList, filter = filter}\r\
	for i = 1,#hier do\r\
		data = Karm.TaskObject.applyFuncHier(hier[i],function(task,data)\r\
							  	local passed = Karm.FilterObject.validateTask(data.filter,task)\r\
							  	if passed then\r\
							  		data.returnList.count = data.returnList.count + 1\r\
							  		data.returnList[data.returnList.count] = task\r\
							  	end\r\
							  	return data\r\
							  end, data\r\
		)\r\
	end\r\
	return data.returnList\r\
end\r\
\r\
-- Old Version\r\
--function Karm.FilterObject.applyFilterHier(filter, taskHier)\r\
--	local hier = taskHier\r\
--	local hierCount = {}\r\
--	local returnList = {count = 0}\r\
----[[	-- Reset the hierarchy if not already done so\r\
--	while hier.parent do\r\
--		hier = hier.parent\r\
--	end]]\r\
--	-- Traverse the task hierarchy here\r\
--	hierCount[hier] = 0\r\
--	while hierCount[hier] < #hier or hier.parent do\r\
--		if not(hierCount[hier] < #hier) then\r\
--			if hier == taskHier then\r\
--				-- Do not go above the passed task\r\
--				break\r\
--			end \r\
--			hier = hier.parent\r\
--		else\r\
--			-- Increment the counter\r\
--			hierCount[hier] = hierCount[hier] + 1\r\
--			local passed = Karm.FilterObject.validateTask(filter,hier[hierCount[hier]])\r\
--			if passed then\r\
--				returnList.count = returnList.count + 1\r\
--				returnList[returnList.count] = hier[hierCount[hier]]\r\
--			end\r\
--			if hier[hierCount[hier]].SubTasks then\r\
--				-- This task has children so go deeper in the hierarchy\r\
--				hier = hier[hierCount[hier]].SubTasks\r\
--				hierCount[hier] = 0\r\
--			end\r\
--		end\r\
--	end		-- while hierCount[hier] < #hier or hier.parent do ends here\r\
--	return returnList\r\
--end\r\
\r\
-- Function to filter out tasks from a list of tasks\r\
function Karm.FilterObject.applyFilterList(filter, taskList)\r\
	local returnList = {count = 0}\r\
	for i=1,#taskList do\r\
		local passed = Karm.FilterObject.validateTask(filter,taskList[i])\r\
		if passed then\r\
			returnList.count = returnList.count + 1\r\
			returnList[returnList.count] = taskList[i]\r\
		end\r\
	end\r\
	return returnList\r\
end\r\
\r\
--[[ The Task Filter should filter the following:\r\
\r\
1. Tasks - Particular tasks with or without its children - This is a table with each element (starting from 1) has a Specified Task ID, Task Title, with 'children' flag. If TaskID = Karm.Globals.ROOTKEY..(Spore File name) then the whole spore will pass the filter\r\
2. Who - People responsible for the task (Boolean) - Boolean string with people IDs with their status in single quotes \"'milind.gupta,A' or 'aryajur,A' and not('milind_gupta,A' or 'milind0x,I')\" - if status not present then taken to be A (Active) \r\
3. Date_Started - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by ,\r\
4. Date_Finished - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by , Karm.Globals.NoDateStr means no date also passes\r\
5. AccessIDs - Boolean expression of IDs and their access permission - \"'milind.gupta,R' or 'aryajur,W' and not('milind_gupta,W' or 'milind0x,W')\", Karm.Globals.NoAccessIDStr means tasks without an Access ID list also pass\r\
6. Status - Member of given list of status types - List of status types separated by commas\r\
7. Priority - Member of given list of priority types - List of priority numbers separated by commas -\"1,2,3\", Karm.Globals.NoPriStr means no priority also passes\r\
8. Date_Due - Member of given end inclusive ranges - List of Date ranges separated by hyphen and ranges separated by , Karm.Globals.NoDateStr means no date also passes\r\
9. Category - Member of given list of Categories - List of categories separated by commas, Karm.Globals.NoCatStr means tasks without any category also pass\r\
10. Sub-Category - Member of given list of Sub-Categories - List of sub-categories separated by commas, Karm.Globals.NoSubCatStr means tasks without any sub-category also pass\r\
11. Tags - Boolean expression of Tags - \"'Technical' or 'Electronics'\" - Tags allow alphanumeric characters spaces and underscores - For no TAG the tag would be Karm.Globals.NoDateStr\r\
12. Schedules - Type of matching - Fully Contained or any overlap with the given ranges\r\
		Type of Schedule - Estimate, Committed, Revisions (L=Latest or the number of revision) or Actual or Latest (means the latest schedule, note Actual is only latest if task is marked DONE)\r\
		Boolean expression different schedule criterias together \r\
		\"'Full,Estimate(L),12/1/2011-12/5/2011,12/10/2011-1/2/2012' and 'Overlap,Revision(L),12/1/2011-1/2/2012' or 'Full,Estimate(L),'..Karm.Globals.NoDateStr\"\r\
		Karm.Globals.NoDateStr signifies no schedule for the type of schedule the type of matching is ignored in this case\r\
13. Script - The custom user script. task is passed in task variable. Executes in the Karm.Globals.safeenv environment. Final result (true or false) is present in the result variable\r\
]]\r\
\r\
-- Function to validate a given task\r\
function Karm.FilterObject.validateTask(filter, task)\r\
	if not filter then\r\
		return true\r\
	end\r\
	-- Check if task ID passes\r\
	if filter.Tasks then\r\
		local matched = false\r\
		for i = 1,#filter.Tasks do\r\
			if string.sub(filter.Tasks[i].TaskID,1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then\r\
				-- A whole spore is marked check if this task belongs to that spore\r\
				-- Check if this is the spore of the task\r\
				if string.sub(filter.Tasks[i].TaskID,#Karm.Globals.ROOTKEY+1,-1) == task.SporeFile then\r\
					if not filter.Tasks[i].Children then\r\
						return false\r\
					end\r\
					matched = true\r\
					break\r\
				end\r\
			else  \r\
				-- Check if the task ID matches\r\
				if filter.Tasks[i].Children then\r\
					-- Children are allowed\r\
					if filter.Tasks[i].TaskID == task.TaskID or \r\
					  filter.Tasks[i].TaskID == string.sub(task.TaskID,1,#filter.Tasks[i].TaskID) then\r\
						matched = true\r\
						break\r\
					end\r\
				else\r\
					if filter.Tasks[i].TaskID == task.TaskID then\r\
						matched = true\r\
						break\r\
					end\r\
				end\r\
			end		-- if filter.Tasks.TaskID == Karm.Globals.ROOTKEY..\"S\" then ends\r\
		end	-- for 1,#filter.Tasks ends here\r\
		if not matched then\r\
			return false\r\
		end\r\
	end\r\
	-- Check if Who passes\r\
	if filter.Who then\r\
		local pattern = \"%'([%w%.%_%,]+)%'\"\r\
		local whoStr = filter.Who\r\
		for id in string.gmatch(filter.Who,pattern) do\r\
			-- Check if the Status is given\r\
			local idc = id\r\
			local st = string.find(idc,\",\")\r\
			local stat\r\
			if st then\r\
				-- Status exists, extract it here\r\
				stat = string.sub(idc,st+1,-1)\r\
				idc = string.sub(idc,1,st-1)\r\
			else\r\
				stat = \"A\"\r\
			end\r\
			-- Check if the id exists in the task\r\
			local result = false\r\
			for i = 1,#task.Who do\r\
				if task.Who[i].ID == idc then\r\
					if stat == \"A\" and string.upper(task.Who[i].Status) == \"ACTIVE\" then\r\
						result = true\r\
						break\r\
					end\r\
					if stat ==\"I\" and string.upper(task.Who[i].Status) ==\"INACTIVE\" then\r\
						result = true\r\
						break\r\
					end\r\
					result = false\r\
					break\r\
				end		-- if task.Who[i].ID == idc then ends\r\
			end		-- for i = 1,#task.Who ends\r\
			whoStr = string.gsub(whoStr,\"'\"..id..\"'\",tostring(result))\r\
		end		-- for id in string.gmatch(filter.Who,pattern) do ends\r\
		-- Check if the boolean passes\r\
		if not loadstring(\"return \"..whoStr)() then\r\
			return false\r\
		end\r\
	end		-- if filter.Who then ends\r\
	\r\
	-- Check if Date Started Passes\r\
	if filter.Start then\r\
		-- Trim the string from leading and trailing spaces\r\
		local strtStr = string.match(filter.Start,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(strtStr,-1,-1)~=\",\" then\r\
			strtStr = strtStr .. \",\"\r\
		end\r\
		local matched = false\r\
		for range in string.gmatch(strtStr,\"(.-),\") do\r\
			-- See if this is a range or a single date\r\
			local strt,stp = string.match(range,\"(.-)%-(.*)\")\r\
			if not strt then\r\
				-- its not a range\r\
				strt = range\r\
				stp = range\r\
			end\r\
			strt = Karm.Utility.toXMLDate(strt)\r\
			stp = Karm.Utility.toXMLDate(stp)\r\
			local taskDate = task.Start\r\
			if strt <= taskDate and taskDate <=stp then\r\
				matched = true\r\
				break\r\
			end\r\
		end\r\
		if not matched then\r\
			return false\r\
		end\r\
	end\r\
\r\
	-- Check if Date Finished Passes\r\
	if filter.Fin then\r\
		-- Trim the string from leading and trailing spaces\r\
		local finStr = string.match(filter.Fin,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(finStr,-1,-1)~=\",\" then\r\
			finStr = finStr .. \",\"\r\
		end\r\
		local matched = false\r\
		for range in string.gmatch(finStr,\"(.-),\") do\r\
			-- Check if this is Karm.Globals.NoDateStr\r\
			if range == Karm.Globals.NoDateStr and not task.Fin then\r\
				matched = true\r\
				break\r\
			end\r\
			-- See if this is a range or a single date\r\
			local strt,stp = string.match(range,\"(.-)%-(.*)\")\r\
			if not strt then\r\
				-- its not a range\r\
				strt = range\r\
				stp = range\r\
			end\r\
			strt = Karm.Utility.toXMLDate(strt)\r\
			stp = Karm.Utility.toXMLDate(stp)\r\
			if task.Fin then\r\
				if strt <= task.Fin and task.Fin <=stp then\r\
					matched = true\r\
					break\r\
				end\r\
			end\r\
		end\r\
		if not matched then\r\
			return false\r\
		end\r\
	end\r\
\r\
	-- Check if Access IDs pass\r\
	if filter.Access then\r\
		local pattern = Karm.Globals.UserIDPattern\r\
		local accStr = filter.Access\r\
		for id in string.gmatch(filter.Access,pattern) do\r\
			local result = false\r\
			if id == Karm.Globals.NoAccessIDStr and not task.Access then\r\
				result = true\r\
			else\r\
				-- Extract the permission character\r\
				local idc = id\r\
				local st = string.find(idc,\",\")\r\
				local perm\r\
	\r\
				perm = string.sub(idc,st+1,-1)\r\
				idc = string.sub(idc,1,st-1)\r\
				\r\
				-- Check if the id exists in the task\r\
				if task.Access then\r\
					for i = 1,#task.Access do\r\
						if task.Access[i].ID == idc then\r\
							if string.upper(perm) == \"R\" and string.upper(task.Access[i].Status) == \"READ ONLY\" then\r\
								result = true\r\
								break\r\
							end\r\
							if string.upper(perm) ==\"W\" and string.upper(task.Access[i].Status) ==\"READ/WRITE\" then\r\
								result = true\r\
								break\r\
							end\r\
							result = false\r\
							break\r\
						end		-- if task.Access[i].ID == idc then ends\r\
					end		-- for i = 1,#task.Access do ends\r\
				end\r\
				if not result then\r\
					-- Check for Read/Write access does the ID exist in the Who table\r\
					if string.upper(perm) == \"W\" then\r\
						for i = 1,#task.Who do\r\
							if task.Who[i].ID == idc then\r\
								if string.upper(task.Who[i].Status) == \"ACTIVE\" then\r\
									result = true\r\
								end\r\
								break\r\
							end\r\
						end		-- for i = 1,#task.Who do ends\r\
					end		-- if string.upper(perm) == \"W\" then ends\r\
				end		-- if not result then ends\r\
			end		-- if id == Karm.Globals.NoAccessIDStr and not task.Access then ends\r\
			accStr = string.gsub(accStr,\"'\"..id..\"'\",tostring(result))\r\
		end		-- for id in string.gmatch(filter.Who,pattern) do ends\r\
		-- Check if the boolean passes\r\
		if not loadstring(\"return \"..accStr)() then\r\
			return false\r\
		end\r\
	end		-- if filter.Access then ends\r\
\r\
	-- Check if Status Passes\r\
	if filter.Status then\r\
		-- Trim the string from leading and trailing spaces\r\
		local statStr = string.match(filter.Status,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(statStr,-1,-1)~=\",\" then\r\
			statStr = statStr .. \",\"\r\
		end\r\
		local matched = false\r\
		for stat in string.gmatch(statStr,\"(.-),\") do\r\
			-- Check if this status matches with what we have in the task\r\
			if task.Status == stat then\r\
				matched = true\r\
				break\r\
			end\r\
		end\r\
		if not matched then\r\
			return false\r\
		end\r\
	end\r\
\r\
	-- Check if Priority Passes\r\
	if filter.Priority then\r\
		-- Trim the string from leading and trailing spaces\r\
		local priStr = string.match(filter.Priority,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(priStr,-1,-1)~=\",\" then\r\
			priStr = priStr .. \",\"\r\
		end\r\
		local matched = false\r\
		for pri in string.gmatch(priStr,\"(.-),\") do\r\
			if pri == Karm.Globals.NoPriStr and not task.Priority then\r\
				matched = true\r\
				break\r\
			end\r\
			-- Check if this priority matches with what we have in the task\r\
			if task.Priority == pri then\r\
				matched = true\r\
				break\r\
			end\r\
		end\r\
		if not matched then\r\
			return false\r\
		end\r\
	end\r\
\r\
	-- Check if Date Due Passes\r\
	if filter.Due then\r\
		-- Trim the string from leading and trailing spaces\r\
		local dueStr = string.match(filter.Due,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(dueStr,-1,-1)~=\",\" then\r\
			dueStr = dueStr .. \",\"\r\
		end\r\
		local matched = false\r\
		for range in string.gmatch(dueStr,\"(.-),\") do\r\
			-- Check if this is Karm.Globals.NoDateStr\r\
			if range == Karm.Globals.NoDateStr and not task.Fin then\r\
				matched = true\r\
				break\r\
			end\r\
			-- See if this is a range or a single date\r\
			local strt,stp = string.match(range,\"(.-)%-(.*)\")\r\
			if not strt then\r\
				-- its not a range\r\
				strt = range\r\
				stp = range\r\
			end\r\
			strt = Karm.Utility.toXMLDate(strt)\r\
			stp = Karm.Utility.toXMLDate(stp)\r\
			if task.Due then\r\
				if strt <= task.Due and task.Due <=stp then\r\
					matched = true\r\
					break\r\
				end\r\
			end\r\
		end\r\
		if not matched then\r\
			return false\r\
		end\r\
	end\r\
\r\
	-- Check if Category Passes\r\
	if filter.Cat then\r\
		-- Trim the string from leading and trailing spaces\r\
		local catStr = string.match(filter.Cat,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(catStr,-1,-1)~=\",\" then\r\
			catStr = catStr .. \",\"\r\
		end\r\
		local matched = false\r\
		for cat in string.gmatch(catStr,\"(.-),\") do\r\
			-- Check if it matches Karm.Globals.NoCatStr\r\
			if cat == Karm.Globals.NoCatStr and not task.Cat then\r\
				matched = true\r\
				break\r\
			end\r\
			-- Check if this status matches with what we have in the task\r\
			if task.Cat == cat then\r\
				matched = true\r\
				break\r\
			end\r\
		end\r\
		if not matched then\r\
			return false\r\
		end\r\
	end\r\
\r\
	-- Check if Sub-Category Passes\r\
	if filter.SubCat then\r\
		-- Trim the string from leading and trailing spaces\r\
		local subCatStr = string.match(filter.SubCat,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(subCatStr,-1,-1)~=\",\" then\r\
			subCatStr = subCatStr .. \",\"\r\
		end\r\
		local matched = false\r\
		for subCat in string.gmatch(subCatStr,\"(.-),\") do\r\
			-- Check if it matches Karm.Globals.NoSubCatStr\r\
			if subCat == Karm.Globals.NoSubCatStr and not task.SubCat then\r\
				matched = true\r\
				break\r\
			end\r\
			-- Check if this status matches with what we have in the task\r\
			if task.SubCat == subCat then\r\
				matched = true\r\
				break\r\
			end\r\
		end\r\
		if not matched then\r\
			return false\r\
		end\r\
	end\r\
\r\
	-- Check if Tags pass\r\
	if filter.Tags then\r\
		local pattern = \"%'([%w%s%_]+)%'\"	-- Tags are allowed alphanumeric characters spaces and underscores\r\
		local tagStr = filter.Tags\r\
		for tag in string.gmatch(filter.Tags,pattern) do\r\
			-- Check if the tag exists in the task\r\
			local result = false\r\
			if tag == Karm.Globals.NoTagStr and not task.Tags then\r\
				result = true\r\
			elseif task.Tags then			\r\
				for i = 1,#task.Tags do\r\
					if task.Tags[i] == tag then\r\
						-- Found the tag in the task\r\
						result = true\r\
						break\r\
					end		-- if task.Tags[i] == tag then ends\r\
				end		-- for i = 1,#task.Tags ends\r\
			end\r\
			tagStr = string.gsub(tagStr,\"'\"..tag..\"'\",tostring(result))\r\
		end		-- for id in string.gmatch(filter.Tags,pattern) do ends\r\
		-- Check if the boolean passes\r\
		if not loadstring(\"return \"..tagStr)() then\r\
			return false\r\
		end\r\
	end		-- if filter.Access then ends\r\
	\r\
	-- Check if the Schedules pass\r\
	if filter.Schedules then\r\
		local schStr = filter.Schedules\r\
		for sch in string.gmatch(filter.Schedules,\"%'(.-)%'\") do\r\
			-- Check if this schedule chunk passes in the task\r\
			-- \"'Full,Estimate,12/1/2011-12/5/2011,12/10/2011-1/2/2012' and 'Overlap,Revision(L),12/1/2011-1/2/2012'\"\r\
			local typeMatch, typeSchedule, ranges, rangeStr, index, result\r\
			local firstComma = string.find(sch,\",\")\r\
			local secondComma = string.find(sch,\",\",firstComma + 1)\r\
			typeMatch = string.sub(sch,1,firstComma-1)\r\
			typeSchedule = string.sub(sch,firstComma + 1,secondComma - 1)\r\
			ranges = {[0]=string.sub(sch,secondComma + 1, -1),count=0}\r\
			rangeStr = ranges[0]\r\
			-- Make sure the string has \",\" at the end\r\
			if string.sub(rangeStr,-1,-1)~=\",\" then\r\
				rangeStr = rangeStr .. \",\"\r\
			end\r\
			-- Now separate individual date ranges\r\
			for range in string.gmatch(rangeStr,\"(.-),\") do\r\
				ranges.count = ranges.count + 1\r\
				ranges[ranges.count] = range\r\
			end\r\
			-- CHeck if the task has a Schedule item\r\
			if not task.Schedules then\r\
				if ranges[0] == Karm.Globals.NoDateStr then\r\
					result = true\r\
				end			\r\
				schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\r\
			else\r\
				-- Type of Schedule - Estimate, Committed, Revision(X) (L=Latest or the number of revision), Actual or Latest (means the latest schedule, note Actual is only latest if task is marked DONE)\r\
				index = nil\r\
				if string.upper(string.sub(typeSchedule,1,#\"ESTIMATE\")) == \"ESTIMATE\" then\r\
					if string.match(typeSchedule,\"%(%d-%)\") then\r\
						-- Get the index number\r\
						index = string.match(typeSchedule,\"%((%d-)%)\")\r\
					else  \r\
						-- Get the latest schedule index\r\
						if ranges[0] == Karm.Globals.NoDateStr then\r\
							result = true\r\
							schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\r\
						elseif task.Schedules.Estimate then\r\
							index = #task.Schedules.Estimate\r\
						else\r\
							schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\r\
						end			\r\
					end\r\
					typeSchedule = \"Estimate\"\r\
				elseif string.upper(typeSchedule) == \"COMMITTED\" then\r\
					typeSchedule = \"Commit\"\r\
					index = 1\r\
				elseif string.upper(string.sub(typeSchedule,1,#\"REVISION\")) == \"REVISION\" then\r\
					if string.match(typeSchedule,\"%(%d-%)\") then\r\
						-- Get the index number\r\
						index = string.match(typeSchedule,\"%((%d-)%)\")\r\
					else  \r\
						-- Get the latest schedule index\r\
						if ranges[0] == Karm.Globals.NoDateStr then\r\
							result = true\r\
							schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\r\
						elseif task.Schedules.Revs then\r\
							index = #task.Schedules.Revs\r\
						else\r\
							schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\r\
						end			\r\
					end\r\
					typeSchedule = \"Revs\"\r\
				elseif string.upper(typeSchedule) == \"ACTUAL\" then\r\
					typeSchedule = \"Actual\"\r\
					index = 1\r\
				elseif string.upper(typeSchedule) == \"LATEST\" then\r\
					-- Find the latest schedule in the task here\r\
					if string.upper(task.Status) == \"DONE\" and task.Schedules.Actual then\r\
						typeSchedule = \"Actual\"\r\
						index = 1\r\
					elseif task.Schedules.Revs then\r\
						-- Actual is not the latest one but Revision is \r\
						typeSchedule = \"Revs\"\r\
						index = task.Schedules.Revs.count\r\
					elseif task.Schedules.Commit then\r\
						-- Actual and Revisions don't exist but Commit does\r\
						typeSchedule = \"Commit\"\r\
						index = 1\r\
					elseif task.Schedules.Estimate then\r\
						-- The latest is Estimate\r\
						typeSchedule = \"Estimate\"\r\
						index = task.Schedules.Estimate.count\r\
					else\r\
						-- typeSchedule is latest but non of the schedule types exist\r\
						-- Check if the range is Karm.Globals.NoDateStr, if not this sch is false\r\
						local result = false\r\
						if ranges[0] == Karm.Globals.NoDateStr then\r\
							result = true\r\
						end\r\
						schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\r\
					end\r\
				else\r\
					wx.wxMessageBox(\"Invalid Type Schedule (\"..typeSchdule..\") specified in filter: \"..sch,\"Filter Error\",\r\
	                            wx.wxOK + wx.wxICON_ERROR, Karm.GUI.frame)\r\
					return false\r\
				end		-- if string.upper(string.sub(typeSchedule,1,#\"ESTIMATE\") == \"ESTIMATE\" then ends  (SETTING of typeSchdule and index)\r\
			end		-- if not task.Schedules then\r\
			if index then\r\
				-- We have a typeSchedule and index\r\
				-- Now loop through the schedule of typeSchedule and index\r\
				local result\r\
				if string.upper(typeMatch) == \"OVERLAP\" then\r\
					result = false\r\
				else\r\
					result = true\r\
				end\r\
				-- First check if range is Karm.Globals.NoDateStr then this schedule should not exist for filter to pass\r\
				if ranges[0] == Karm.Globals.NoDateStr and task.Schedules[typeSchedule] and not task.Schedules[typeSchedule][index] then\r\
					result = true\r\
				elseif task.Schedules[typeSchedule] and task.Schedules[typeSchedule][index] then\r\
					for i = 1,#task.Schedules[typeSchedule][index].Period do\r\
						-- Is the date in range?\r\
						local inrange = false\r\
						for j = 1,#ranges do\r\
							local strt,stp = string.match(ranges[j],\"(.-)%-(.*)\")\r\
							if not strt then\r\
								-- its not a range\r\
								strt = ranges[j]\r\
								stp = ranges[j]\r\
							end\r\
							strt = Karm.Utility.toXMLDate(strt)\r\
							stp = Karm.Utility.toXMLDate(stp)\r\
							if strt <= task.Schedules[typeSchedule][index].Period[i].Date and task.Schedules[typeSchedule][index].Period[i].Date <=stp then\r\
								inrange = true\r\
							end\r\
						end		-- for j = 1,#ranges do ends\r\
						if inrange and string.upper(typeMatch) == \"OVERLAP\" then\r\
							-- This date overlaps\r\
							result = true\r\
							break\r\
						elseif not inrange and string.upper(typeMatch) == \"FULL\" then\r\
							-- This portion is not contained in filter\r\
							result = false\r\
							break\r\
						end\r\
					end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends\r\
				end	-- if task.Schedules[typeSchedule][index] then ends\r\
				schStr = string.gsub(schStr,string.gsub(\"'\"..sch..\"'\",\"(%W)\",\"%%%1\"),tostring(result))\r\
			end		-- if index then ends\r\
		end		-- for sch in string.gmatch(filter.Schedules,\"%'(.-)%'\") do ends\r\
		-- Check if the boolean passes\r\
		if not loadstring(\"return \"..schStr)() then\r\
			return false\r\
		end\r\
	end		-- if filter.Schedules then ends\r\
\r\
	if filter.Script then\r\
		local safeenv = {}\r\
		setmetatable(safeenv,{__index = Karm.Globals.safeenv})\r\
		local func,message = loadstring(filter.Script)\r\
		if not func then\r\
			return false\r\
		end\r\
		safeenv.task = task\r\
		setfenv(func,safeenv)\r\
		func()\r\
		if not safeenv.result then\r\
			return false\r\
		end\r\
	end\r\
	-- All pass\r\
	return true\r\
end		-- function Karm.FilterObject.validateTask(filter, task) ends\r\
"
__MANY2ONEFILES['FilterForm']="local requireLuaString = requireLuaString\
-----------------------------------------------------------------------------\r\
-- Application: Karm\r\
-- Purpose:     Karm application Criteria Entry form UI creation and handling file\r\
-- Author:      Milind Gupta\r\
-- Created:     2/09/2012\r\
-----------------------------------------------------------------------------\r\
local prin\r\
if Karm.Globals.__DEBUG then\r\
	prin = print\r\
end\r\
local print = prin \r\
local wx = wx\r\
local io = io\r\
local wxaui = wxaui\r\
local bit = bit\r\
local GUI = Karm.GUI\r\
local tostring = tostring\r\
local loadfile = loadfile\r\
local loadstring = loadstring\r\
local setfenv = setfenv\r\
local string = string\r\
local Globals = Karm.Globals\r\
local setmetatable = setmetatable\r\
local NewID = Karm.NewID\r\
local type = type\r\
local math = math\r\
local error = error\r\
local modname = ...\r\
local tableToString = Karm.Utility.tableToString\r\
local pairs = pairs\r\
local applyFilterHier = Karm.FilterObject.applyFilterHier\r\
local collectFilterDataHier = Karm.accumulateTaskDataHier\r\
local CW = requireLuaString('CustomWidgets')\r\
\r\
\r\
local GlobalFilter = function() \r\
		return Karm.Filter \r\
	end\r\
	\r\
local SData = function()\r\
		return Karm.SporeData\r\
	end\r\
\r\
local MainFilter\r\
local SporeData\r\
\r\
module(modname)\r\
\r\
--local modname = ...\r\
\r\
--M = {}\r\
--package.loaded[modname] = M\r\
--setmetatable(M,{[\"__index\"]=_G})\r\
--setfenv(1,M)\r\
\r\
-- Local filter table to store the filter criteria\r\
local filter = {}\r\
local filterData = {}\r\
\r\
local noStr = {\r\
	Cat = Globals.NoCatStr,\r\
	SubCat = Globals.NoSubCatStr,\r\
	Priority = Globals.NoPriStr,\r\
	Due = Globals.NoDateStr,\r\
	Fin = Globals.NoDateStr,\r\
	ScheduleRange = Globals.NoDateStr,\r\
	Tags = Globals.NoTagStr,\r\
	Access = Globals.NoAccessIDStr\r\
}\r\
\r\
local function SelTaskPress(event)\r\
	setfenv(1,package.loaded[modname])\r\
	local frame = wx.wxFrame(frame, wx.wxID_ANY, \"Select Task\", wx.wxDefaultPosition,\r\
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)\r\
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
	local taskTree = wx.wxTreeCtrl(frame, wx.wxID_ANY, wx.wxDefaultPosition,wx.wxSize(0.9*GUI.initFrameW, 0.9*GUI.initFrameH),bit.bor(wx.wxTR_SINGLE,wx.wxTR_HAS_BUTTONS))\r\
	MainSizer:Add(taskTree, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	local buttonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
	local OKButton = wx.wxButton(frame, wx.wxID_ANY, \"OK\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
	local CancelButton = wx.wxButton(frame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
	local CheckBox = wx.wxCheckBox(frame, wx.wxID_ANY, \"Subtasks\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
	\r\
	if filter.TasksSet and filter.TasksSet[1].Children then\r\
		CheckBox:SetValue(true)\r\
	end\r\
	buttonSizer:Add(OKButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	buttonSizer:Add(CancelButton,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	buttonSizer:Add(CheckBox,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	MainSizer:Add(buttonSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	\r\
	-- Now populate the tree with all the tasks\r\
	\r\
	-- Add the root\r\
	local root = taskTree:AddRoot(\"Task Spores\")\r\
	local treeData = {}\r\
	treeData[root:GetValue()] = {Key = Globals.ROOTKEY, Parent = nil, Title = \"Task Spores\"}\r\
    if SporeData[0] > 0 then\r\
-- Populate the tree control view\r\
		local count = 0\r\
		-- Loop through all the spores\r\
        for k,v in pairs(SporeData) do\r\
        	if k~=0 then\r\
            -- Get the tasks in the spore\r\
-- Add the spore to the TaskTree\r\
				-- Find the name of the file\r\
				local strVar\r\
        		local intVar1 = -1\r\
				count = count + 1\r\
            	for intVar = #k,1,-1 do\r\
                	if string.sub(k, intVar, intVar) == \".\" then\r\
                    	intVar1 = intVar\r\
                	end\r\
                	if string.sub(k, intVar, intVar) == \"\\\\\" or string.sub(k, intVar, intVar) == \"/\" then\r\
                    	strVar = string.sub(k, intVar + 1, intVar1-1)\r\
                    	break\r\
                	end\r\
            	end\r\
            	-- Add the spore node\r\
	            local currNode = taskTree:AppendItem(root,strVar)\r\
				treeData[currNode:GetValue()] = {Key = Globals.ROOTKEY..k, Parent = root, Title = strVar}\r\
				if filter.TasksSet and #filter.TasksSet[1].TaskID > #Globals.ROOTKEY and \r\
				  string.sub(filter.TasksSet[1].TaskID,#Globals.ROOTKEY + 1, -1) == k then\r\
					taskTree:EnsureVisible(currNode)\r\
					taskTree:SelectItem(currNode)\r\
				end\r\
				local taskList = applyFilterHier(filter, v)\r\
-- Now add the tasks under the spore in the TaskTree\r\
            	if taskList.count > 0 then  --There are some tasks passing the criteria in this spore\r\
	                -- Add the 1st element under the spore\r\
	                local parent = currNode\r\
		            currNode = taskTree:AppendItem(parent,taskList[1].Title)\r\
					treeData[currNode:GetValue()] = {Key = taskList[1].TaskID, Parent = parent, Title = taskList[1].Title}\r\
	                for intVar = 2,taskList.count do\r\
	                	local cond1 = treeData[currNode:GetValue()].Key ~= Globals.ROOTKEY..k\r\
	                	local cond2 = #taskList[intVar].TaskID > #treeData[currNode:GetValue()].Key\r\
	                	local cond3 = string.sub(taskList[intVar].TaskID, 1, #treeData[currNode:GetValue()].Key + 1) == treeData[currNode:GetValue()].Key..\"_\"\r\
                    	while cond1 and not (cond2 and cond3) do\r\
                        	-- Go up the hierarchy\r\
                        	currNode = treeData[currNode:GetValue()].Parent\r\
		                	cond1 = treeData[currNode:GetValue()].Key ~= Globals.ROOTKEY..k\r\
		                	cond2 = #taskList[intVar].TaskID > #treeData[currNode:GetValue()].Key\r\
		                	cond3 = string.sub(taskList[intVar].TaskID, 1, #treeData[currNode:GetValue()].Key + 1) == treeData[currNode:GetValue()].Key..\"_\"\r\
                        end\r\
                    	-- Now currNode has the node which is the right parent\r\
		                parent = currNode\r\
			            currNode = taskTree:AppendItem(parent,taskList[intVar].Title)\r\
						treeData[currNode:GetValue()] = {Key = taskList[intVar].TaskID, Parent = parent, Title = taskList[intVar].Title}\r\
                    end\r\
	            end  -- if taskList.count > 0 then ends\r\
			end		-- if k~=0 then ends\r\
-- Repeat for all spores\r\
        end		-- for k,v in pairs(SporeData) do ends\r\
    end  -- if SporeData[0] > 0 then ends\r\
    \r\
	-- Expand the root element\r\
	taskTree:Expand(root)\r\
	\r\
	-- Connect the button events\r\
	OKButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
	function (event)\r\
		setfenv(1,package.loaded[modname])\r\
		local sel = taskTree:GetSelection()\r\
		-- Setup the filter\r\
		filter.TasksSet = {}\r\
		if treeData[sel:GetValue()].Key == Globals.ROOTKEY then\r\
			filter.TasksSet = nil\r\
		else\r\
			filter.TasksSet[1] = {}\r\
			-- This is a spore node\r\
			if CheckBox:GetValue() then\r\
				filter.TasksSet[1].Children = true\r\
			end\r\
			filter.TasksSet[1].TaskID = treeData[sel:GetValue()].Key\r\
			filter.TasksSet[1].Title =  treeData[sel:GetValue()].Title\r\
		end\r\
		-- Setup the label properly\r\
		if filter.TasksSet then\r\
			if filter.TasksSet[1].Children then\r\
				FilterTask:SetLabel(taskTree:GetItemText(sel)..\" and Children\")\r\
			else\r\
				FilterTask:SetLabel(taskTree:GetItemText(sel))\r\
			end\r\
		else\r\
			FilterTask:SetLabel(\"No Task Selected\")\r\
		end	\r\
		frame:Close()\r\
	end\r\
	)\r\
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
	function (event)\r\
		setfenv(1,package.loaded[modname])		\r\
		frame:Close()\r\
	end\r\
	)\r\
	\r\
	\r\
	frame:SetSizer(MainSizer)\r\
	MainSizer:SetSizeHints(frame)\r\
	frame:Layout()\r\
	frame:Show(true)\r\
end		-- local function SelTaskPress(event) ends\r\
\r\
local function initializeFilterForm(filterData)\r\
	-- Clear Task Selection\r\
	FilterTask:SetLabel(\"No Task Selected\")\r\
	-- Clear Category\r\
	CatCtrl:ResetCtrl()\r\
	-- Clear Sub-Category\r\
	SubCatCtrl:ResetCtrl()\r\
	-- Clear Priority\r\
	PriCtrl:ResetCtrl()\r\
	-- Clear Status\r\
	StatCtrl:ResetCtrl()\r\
	-- Clear Tags List\r\
	TagList:DeleteAllItems()\r\
	TagBoolCtrl:ResetCtrl()\r\
	-- Clear Dates\r\
	dateStarted:ResetCtrl()\r\
	dateFinished:ResetCtrl()\r\
	dateDue:ResetCtrl()\r\
	-- Who and Access\r\
	whoCtrl:ResetCtrl()\r\
	WhoBoolCtrl:ResetCtrl()\r\
	accCtrl:ResetCtrl()\r\
	accBoolCtrl:ResetCtrl()\r\
	-- Schedules\r\
	schDateRanges:ResetCtrl()\r\
	SchBoolCtrl:ResetCtrl()\r\
	filter = {}		-- Clear the filter\r\
	-- Fill the data in the controls\r\
	CatCtrl:AddListData(filterData.Cat)\r\
	SubCatCtrl:AddListData(filterData.SubCat)\r\
	PriCtrl:AddListData(filterData.Priority)\r\
	StatCtrl:AddListData(Globals.StatusList)\r\
	ScriptBox:Clear()\r\
	if filterData.Tags then\r\
		for i=1,#filterData.Tags do\r\
			CW.InsertItem(TagList,filterData.Tags[i])\r\
		end\r\
	end\r\
	if filterData.Who then\r\
		for i=1,#filterData.Who do\r\
			whoCtrl:InsertItem(filterData.Who[i], false)\r\
		end\r\
	end\r\
	\r\
	if filterData.Access then\r\
		for i=1,#filterData.Access do\r\
			accCtrl:InsertItem(filterData.Access[i], false)\r\
		end\r\
	end\r\
end\r\
\r\
local function setfilter(f)\r\
	-- Initialize the form\r\
	initializeFilterForm(filterData)\r\
	-- Set the task details\r\
	local str = \"\"\r\
	if f.Tasks then\r\
		filter.TasksSet = {[1]={}}\r\
		if f.Tasks[1].Title then\r\
			str = f.Tasks[1].Title\r\
			filter.TasksSet[1].Title = str\r\
		else\r\
			for k,v in pairs(SporeData) do\r\
				if k~=0 then\r\
					local taskList = applyFilterHier({Tasks={[1]={TaskID = f.Tasks.TaskID}}},v)\r\
					if #taskList then\r\
						str = taskList[1].Title\r\
						break\r\
					end\r\
				end		-- if k~=0 then ends\r\
			end		-- for k,v in pairs(SporeData) do ends\r\
			if not str then\r\
				str = \"TASK ID: \"..f.Tasks[1].TaskID\r\
				filter.TasksSet[1].Title = str\r\
			end\r\
		end	\r\
		filter.TasksSet[1].TaskID = f.Tasks[1].TaskID\r\
		filter.TasksSet[1].Children = f.Tasks[1].Children\r\
		if f.Tasks[1].Children then\r\
			str = str..\" and Children\"\r\
		end\r\
		FilterTask:SetLabel(str)\r\
	end\r\
	-- Set Category data\r\
	if f.Cat then\r\
		-- Separate out the items in the comma\r\
		-- Trim the string from leading and trailing spaces\r\
		local catStr = string.match(f.Cat,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(catStr,-1,-1)~=\",\" then\r\
			catStr = catStr .. \",\"\r\
		end\r\
		local items = {}\r\
		for cat in string.gmatch(catStr,\"(.-),\") do\r\
			-- Trim leading and trailing spaces\r\
			cat = string.match(cat,\"^%s*(.-)%s*$\")			\r\
			-- Check if it matches Globals.NoCatStr\r\
			if cat == Globals.NoCatStr then\r\
				CatCtrl.CheckBox:SetValue(true)\r\
			else\r\
				items[#items + 1] = cat\r\
			end\r\
		end\r\
		CatCtrl:AddSelListData(items)\r\
	end		-- if f.Cat then ends\r\
	-- Set Sub-Category data\r\
	if f.SubCat then\r\
		-- Separate out the items in the comma\r\
		-- Trim the string from leading and trailing spaces\r\
		local subCatStr = string.match(f.SubCat,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(subCatStr,-1,-1)~=\",\" then\r\
			subCatStr = subCatStr .. \",\"\r\
		end\r\
		local items = {}\r\
		for subCat in string.gmatch(subCatStr,\"(.-),\") do\r\
			-- Trim leading and trailing spaces\r\
			subCat = string.match(subCat,\"^%s*(.-)%s*$\")			\r\
			-- Check if it matches Globals.NoSubCatStr\r\
			if subCat == Globals.NoSubCatStr then\r\
				SubCatCtrl.CheckBox:SetValue(true)\r\
			else\r\
				items[#items + 1] = subCat\r\
			end\r\
		end\r\
		SubCatCtrl:AddSelListData(items)\r\
	end		-- if f.Cat then ends\r\
	if f.Tags then\r\
		TagBoolCtrl:setExpression(f.Tags)\r\
	end		-- if f.Tags then ends\r\
	-- Set Priority data\r\
	if f.Priority then\r\
		-- Separate out the items in the comma\r\
		-- Trim the string from leading and trailing spaces\r\
		local priStr = string.match(f.Priority,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(priStr,-1,-1)~=\",\" then\r\
			priStr = priStr .. \",\"\r\
		end\r\
		local items = {}\r\
		for pri in string.gmatch(priStr,\"(.-),\") do\r\
			-- Trim leading and trailing spaces\r\
			pri = string.match(pri,\"^%s*(.-)%s*$\")			\r\
			-- Check if it matches Globals.NoPriStr\r\
			if pri == Globals.NoPriStr then\r\
				PriCtrl.CheckBox:SetValue(true)\r\
			else\r\
				items[#items + 1] = pri\r\
			end\r\
		end\r\
		PriCtrl:AddSelListData(items)\r\
	end		-- if f.Priority then ends\r\
	-- Set Status data\r\
	if f.Status then\r\
		-- Separate out the items in the comma\r\
		-- Trim the string from leading and trailing spaces\r\
		local statStr = string.match(f.Status,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(statStr,-1,-1)~=\",\" then\r\
			statStr = statStr .. \",\"\r\
		end\r\
		local items = {}\r\
		for stat in string.gmatch(statStr,\"(.-),\") do\r\
			-- Trim leading and trailing spaces\r\
			stat = string.match(stat,\"^%s*(.-)%s*$\")			\r\
			items[#items + 1] = stat\r\
		end\r\
		StatCtrl:AddSelListData(items)\r\
	end		-- if f.Status then ends\r\
	-- Who items\r\
	if f.Who then\r\
		WhoBoolCtrl:setExpression(f.Who)\r\
	end\r\
	-- Access items\r\
	if f.Access then\r\
		accBoolCtrl:setExpression(f.Access)\r\
	end		-- if f.Tags then ends\r\
	-- Set Start Date data\r\
	if f.Start then\r\
		do\r\
			-- Separate out the items in the comma\r\
			-- Trim the string from leading and trailing spaces\r\
			local strtStr = string.match(f.Start,\"^%s*(.-)%s*$\")\r\
			-- Make sure the string has \",\" at the end\r\
			if string.sub(strtStr,-1,-1)~=\",\" then\r\
				strtStr = strtStr .. \",\"\r\
			end\r\
			local items = {}\r\
			for strt in string.gmatch(strtStr,\"(.-),\") do\r\
				-- Trim leading and trailing spaces\r\
				strt = string.match(strt,\"^%s*(.-)%s*$\")\r\
				if strt ~= \"\" then			\r\
					items[#items + 1] = strt\r\
				end\r\
			end\r\
			dateStarted:setRanges(items)\r\
		end		-- do for f.Start\r\
	end	\r\
	-- Set Due Date data\r\
	if f.Due then\r\
		-- Separate out the items in the comma\r\
		-- Trim the string from leading and trailing spaces\r\
		local dueStr = string.match(f.Due,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(dueStr,-1,-1)~=\",\" then\r\
			dueStr = dueStr .. \",\"\r\
		end\r\
		local items = {}\r\
		dateDue:setCheckBoxState(nil)\r\
		for due in string.gmatch(dueStr,\"(.-),\") do\r\
			-- Trim leading and trailing spaces\r\
			due = string.match(due,\"^%s*(.-)%s*$\")\r\
			if due == noStr.Due then\r\
				dateDue:setCheckBoxState(true)\r\
			elseif due ~= \"\" then			\r\
				items[#items + 1] = due\r\
			end\r\
		end\r\
		dateDue:setRanges(items)\r\
	end		-- if f.Due ends here	\r\
	-- Set Finish Date data\r\
	if f.Fin then\r\
		-- Separate out the items in the comma\r\
		-- Trim the string from leading and trailing spaces\r\
		local finStr = string.match(f.Fin,\"^%s*(.-)%s*$\")\r\
		-- Make sure the string has \",\" at the end\r\
		if string.sub(finStr,-1,-1)~=\",\" then\r\
			finStr = finStr .. \",\"\r\
		end\r\
		local items = {}\r\
		dateFinished:setCheckBoxState(nil)\r\
		for fin in string.gmatch(finStr,\"(.-),\") do\r\
			-- Trim leading and trailing spaces\r\
			fin = string.match(fin,\"^%s*(.-)%s*$\")\r\
			if fin == noStr.Fin then\r\
				dateFinished:setCheckBoxState(true)\r\
			elseif fin ~= \"\" then			\r\
				items[#items + 1] = fin\r\
			end\r\
		end\r\
		dateFinished:setRanges(items)\r\
	end		-- if f.Due ends here	\r\
	-- Set the Schedules Data\r\
	if f.Schedules then\r\
		SchBoolCtrl:setExpression(f.Schedules)\r\
	end		-- if f.Schedules ends here\r\
	-- Custom Script\r\
	if f.Script then\r\
		ScriptBox:SetValue(f.Script)\r\
	end\r\
end\r\
\r\
local function synthesizeFilter()\r\
	local f = {}\r\
	-- Get the tasks information\r\
	if filter.TasksSet then\r\
		f.Tasks = filter.TasksSet\r\
	end\r\
	-- Get Who information here\r\
	f.Who = WhoBoolCtrl:BooleanExpression()\r\
	-- Date Started\r\
	local str = \"\"\r\
	local items = dateStarted:getSelectedItems()\r\
	for i = 1,#items do\r\
		str = str..items[i]..\",\"\r\
	end\r\
	if str ~= \"\" then \r\
		f.Start = str:sub(1,-2)\r\
	end\r\
	-- Date Finished\r\
	str = \"\"\r\
	items = dateFinished:getSelectedItems()\r\
	for i = 1,#items do\r\
		str = str..items[i]..\",\"\r\
	end \r\
	if items[0] then\r\
		str = str..Globals.NoDateStr..\",\"\r\
	end\r\
	if str ~= \"\" then\r\
		f.Fin = str:sub(1,-2)\r\
	end\r\
	-- Access information\r\
	f.Access = accBoolCtrl:BooleanExpression()\r\
	-- Status Information\r\
	str = \"\"\r\
	items = StatCtrl:getSelectedItems()\r\
	for i = 1,#items do\r\
		str = str..items[i]..\",\"\r\
	end\r\
	if str ~= \"\" then \r\
		f.Status = str:sub(1,-2)\r\
	end\r\
	-- Priority\r\
	str = \"\"\r\
	items = PriCtrl:getSelectedItems()\r\
	for i = 1,#items do\r\
		str = str..items[i]..\",\"\r\
	end \r\
	if items[0] then\r\
		str = str..Globals.NoPriStr..\",\"\r\
	end\r\
	if str ~= \"\" then\r\
		f.Priority = str:sub(1,-2)\r\
	end\r\
	-- Due Date\r\
	str = \"\"\r\
	items = dateDue:getSelectedItems()\r\
	for i = 1,#items do\r\
		str = str..items[i]..\",\"\r\
	end \r\
	if items[0] then\r\
		str = str..Globals.NoDateStr..\",\"\r\
	end\r\
	if str ~= \"\" then\r\
		f.Due = str:sub(1,-2)\r\
	end\r\
	-- Category\r\
	str = \"\"\r\
	items = CatCtrl:getSelectedItems()\r\
	for i = 1,#items do\r\
		str = str..items[i]..\",\"\r\
	end \r\
	if items[0] then\r\
		str = str..Globals.NoCatStr..\",\"\r\
	end\r\
	if str ~= \"\" then\r\
		f.Cat = str:sub(1,-2)\r\
	end\r\
	-- Sub-Category\r\
	str = \"\"\r\
	items = SubCatCtrl:getSelectedItems()\r\
	for i = 1,#items do\r\
		str = str..items[i]..\",\"\r\
	end \r\
	if items[0] then\r\
		str = str..Globals.NoSubCatStr..\",\"\r\
	end\r\
	if str ~= \"\" then\r\
		f.SubCat = str:sub(1,-2)\r\
	end\r\
	-- Tags\r\
	f.Tags = TagBoolCtrl:BooleanExpression()\r\
	if TagCheckBox:GetValue() then\r\
		f.Tags = \"(\"..f.Tags..\") or \"..Globals.NoTagStr\r\
	end\r\
	-- Schedule\r\
	f.Schedules = SchBoolCtrl:BooleanExpression()\r\
	-- Custom Script\r\
	if ScriptBox:GetValue() ~= \"\" then\r\
		local script = ScriptBox:GetValue()\r\
		local result, msg = loadstring(script)\r\
		if not result then\r\
			wx.wxMessageBox(\"Unable to compile the script. Error: \"..msg..\".\\n Please correct and try again.\",\r\
                            \"Script Compile Error\",wx.wxOK + wx.wxCENTRE, frame)\r\
            return nil\r\
		end\r\
		f.Script = script\r\
	end\r\
	return f\r\
end\r\
\r\
local function loadFilter(event)\r\
	setfenv(1,package.loaded[modname])\r\
	local ValidFilter = function(file)\r\
		local safeenv = {}\r\
		setmetatable(safeenv, {__index = Globals.safeenv})\r\
		local f,message = loadfile(file)\r\
		if not f then\r\
			return nil,message\r\
		end\r\
		setfenv(f,safeenv)\r\
		f()\r\
		if safeenv.filter and type(safeenv.filter) == \"table\" then\r\
			if safeenv.filter.Script then\r\
				f, message = loadstring(safeenv.filter.Script)\r\
				if not f then\r\
					return nil,\"Cannot compile custom script in filter. Error: \"..message\r\
				end\r\
			end\r\
			return safeenv.filter\r\
		else\r\
			return nil,\"Cannot find a valid filter in the file.\"\r\
		end\r\
	end\r\
    local fileDialog = wx.wxFileDialog(frame, \"Open file\",\r\
                                       \"\",\r\
                                       \"\",\r\
                                       \"Karm Filter files (*.kff)|*.kff|Text files (*.txt)|*.txt|All files (*)|*\",\r\
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)\r\
    if fileDialog:ShowModal() == wx.wxID_OK then\r\
    	local result,message = ValidFilter(fileDialog:GetPath())\r\
        if not result then\r\
            wx.wxMessageBox(\"Unable to load file '\"..fileDialog:GetPath()..\"'.\\n \"..message,\r\
                            \"File Load Error\",\r\
                            wx.wxOK + wx.wxCENTRE, frame)\r\
        else\r\
        	setfilter(result)\r\
        end\r\
    end\r\
    fileDialog:Destroy()\r\
end\r\
\r\
local function saveFilter(event)\r\
	setfenv(1,package.loaded[modname])\r\
    local fileDialog = wx.wxFileDialog(frame, \"Save File\",\r\
                                       \"\",\r\
                                       \"\",\r\
                                       \"Karm Filter files (*.kff)|*.kff|Text files (*.txt)|*.txt|All files (*)|*\",\r\
                                       wx.wxFD_SAVE)\r\
    if fileDialog:ShowModal() == wx.wxID_OK then\r\
    	local file,err = io.open(fileDialog:GetPath(),\"w+\")\r\
    	if not file then\r\
            wx.wxMessageBox(\"Unable to save as file '\"..fileDialog:GetPath()..\"'.\\n \"..err,\r\
                            \"File Save Error\",\r\
                            wx.wxOK + wx.wxCENTRE, frame)\r\
        else\r\
        	local fil = synthesizeFilter()\r\
        	if fil then\r\
        		file:write(\"filter=\"..tableToString(fil))\r\
        	end\r\
        	file:close()\r\
        end\r\
    end\r\
    fileDialog:Destroy()\r\
\r\
end\r\
\r\
-- Customized multiselect control\r\
do\r\
\r\
	local UpdateFilter = function(o)\r\
		local SelList = o:getSelectedItems()\r\
		local filterIndex = o.filterIndex\r\
		local str = \"\"\r\
		for i = 1,#SelList do\r\
			str = str..SelList[i]..\",\"\r\
		end\r\
		-- Finally Check if none also selected\r\
		if SelList[0] then\r\
			str = str..noStr[filterIndex]..\",\"\r\
		end\r\
		if str ~= \"\" then\r\
			filter[filterIndex]=string.sub(str,1,-2) -- remove the comma and add it\r\
		else\r\
			filter[filterIndex]=nil\r\
		end\r\
	end\r\
\r\
	MultiSelectCtrl = function(parent, filterIndex, noneSelection, LItems, RItems)\r\
		if not filterIndex then\r\
			error(\"Need a filterIndex for the MultiSelect Control\",2)\r\
		end\r\
		local o = CW.MultiSelectCtrl(parent,LItems,RItems,noneSelection)\r\
		o.filterIndex = filterIndex\r\
		o.UpdateFilter = UpdateFilter\r\
		return o\r\
	end\r\
\r\
end\r\
\r\
-- Customized Date Range control\r\
do\r\
\r\
	local UpdateFilter = function(o)\r\
		local SelList = o:getSelectedItems()\r\
		local filterIndex = o.filterIndex\r\
		local str = \"\"\r\
		for i = 1,#SelList do\r\
			str = str..SelList[i]..\",\"\r\
		end\r\
		-- Finally Check if none also selected\r\
		if SelList[0] then\r\
			str = str..noStr[filterIndex]..\",\"\r\
		end\r\
		if str ~= \"\" then\r\
			filter[filterIndex]=string.sub(str,1,-2) -- remove the comma and add it\r\
		else\r\
			filter[filterIndex]=nil\r\
		end\r\
	end\r\
\r\
	DateRangeCtrl = function(parent, filterIndex, noneSelection, heading)\r\
		if not filterIndex then\r\
			error(\"Need a filterIndex for the Date Range Control\",2)\r\
		end\r\
		local o = CW.DateRangeCtrl(parent, noneSelection, heading)\r\
		o.filterIndex = filterIndex\r\
		o.UpdateFilter = UpdateFilter\r\
		return o\r\
	end\r\
\r\
end\r\
\r\
-- Customized Boolean Tree Control\r\
do\r\
\r\
	local UpdateFilter = function(o)\r\
		local filterText = o:BooleanExpression()\r\
		if filterText == \"\" then\r\
			filter[o.filterIndex]=nil\r\
		else\r\
			filter[o.filterIndex]=filterText\r\
		end\r\
	end\r\
	\r\
	BooleanTreeCtrl = function(parent,sizer,getInfoFunc,filterIndex)\r\
		if not filterIndex then\r\
			error(\"Need a filterIndex for the Boolean Tree Control\",2)\r\
		end\r\
		local o = CW.BooleanTreeCtrl(parent,sizer,getInfoFunc)\r\
		o.filterIndex = filterIndex\r\
		o.UpdateFilter = UpdateFilter\r\
		return o	\r\
	end\r\
\r\
end\r\
\r\
-- Customized Check List Control\r\
do\r\
	local getSelectionFunc = function(obj)\r\
		-- Return the selected item in List\r\
		local o = obj		-- Declare an upvalue\r\
		return function()\r\
			local items = o:getSelectedItems()\r\
			if not items[1] then\r\
				return nil\r\
			else\r\
				return items[1].itemText..\",\"..items[1].checked\r\
			end\r\
		end\r\
	end\r\
	\r\
	CheckListCtrl = function(parent,noneSelection,checkedText,uncheckedText)\r\
		local o = CW.CheckListCtrl(parent,noneSelection,checkedText,uncheckedText,true)\r\
		o.getSelectionFunc = getSelectionFunc\r\
		return o\r\
	end\r\
\r\
end\r\
\r\
function filterFormActivate(parent, callBack)\r\
	MainFilter = GlobalFilter()\r\
	SporeData = SData()\r\
	-- Accumulate Filter Data across all spores\r\
	-- Loop through all the spores\r\
	for k,v in pairs(SporeData) do\r\
		if k~=0 then\r\
			collectFilterDataHier(filterData,v)\r\
		end		-- if k~=0 then ends\r\
	end		-- for k,v in pairs(SporeData) do ends\r\
	\r\
	frame = wx.wxFrame(parent, wx.wxID_ANY, \"Filter Form\", wx.wxDefaultPosition,\r\
		wx.wxSize(GUI.initFrameW, GUI.initFrameH), wx.wxDEFAULT_FRAME_STYLE)\r\
	-- Create tool bar\r\
	ID_LOAD = NewID()\r\
	ID_SAVE = NewID()\r\
	local toolBar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)\r\
	local toolBmpSize = toolBar:GetToolBitmapSize()\r\
\r\
	toolBar:AddTool(ID_LOAD, \"Load\", wx.wxArtProvider.GetBitmap(wx.wxART_GO_DIR_UP, wx.wxART_MENU, toolBmpSize), \"Load Filter Criteria\")\r\
	toolBar:AddTool(ID_SAVE, \"Save\", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize), \"Save Filter Criteria\")\r\
	toolBar:Realize()\r\
	\r\
	local MainSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
		MainBook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxNB_TOP + wxaui.wxAUI_NB_WINDOWLIST_BUTTON)\r\
\r\
		-- Task, Categories and Sub-Categories Page\r\
		TandC = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			local TandCSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
				local TaskSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
				SelTaskButton = wx.wxButton(TandC, wx.wxID_ANY, \"Select Task\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				TaskSizer:Add(SelTaskButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				FilterTask = wx.wxStaticText(TandC, wx.wxID_ANY, \"No Task Selected\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
				TaskSizer:Add(FilterTask, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				ClearTaskButton = wx.wxButton(TandC, wx.wxID_ANY, \"Clear Task\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
				TaskSizer:Add(ClearTaskButton, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				TandCSizer:Add(TaskSizer, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
				CategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, \"Select Categories\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
				TandCSizer:Add(CategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				\r\
				-- Category List boxes and buttons\r\
				CatCtrl = MultiSelectCtrl(TandC,\"Cat\",true,filterData.Cat)\r\
				TandCSizer:Add(CatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				\r\
				SubCategoryLabel = wx.wxStaticText(TandC, wx.wxID_ANY, \"Select Sub-Categories\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
				TandCSizer:Add(SubCategoryLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				-- Sub Category Listboxes and Buttons\r\
				SubCatCtrl = MultiSelectCtrl(TandC,\"SubCat\",true,filterData.SubCat)\r\
				TandCSizer:Add(SubCatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			\r\
			TandC:SetSizer(TandCSizer)\r\
			TandCSizer:SetSizeHints(TandC)\r\
		MainBook:AddPage(TandC, \"Task and Category\")\r\
		\r\
		-- Priorities Status and Tags page\r\
		PSandTag = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			local PSandTagSizer = wx.wxBoxSizer(wx.wxVERTICAL) \r\
				PriorityLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, \"Select Priorities\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
				PSandTagSizer:Add(PriorityLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				\r\
				-- Priority List boxes and buttons\r\
				PriCtrl = MultiSelectCtrl(PSandTag,\"Priority\",true,filterData.Priority)\r\
				PSandTagSizer:Add(PriCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
				StatusLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, \"Select Status\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
				PSandTagSizer:Add(StatusLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				\r\
				-- Status List boxes and buttons\r\
				StatCtrl = MultiSelectCtrl(PSandTag,\"Status\",false,Globals.StatusList)\r\
				PSandTagSizer:Add(StatCtrl.Sizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
				TagsLabel = wx.wxStaticText(PSandTag, wx.wxID_ANY, \"Select Tags\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
				PSandTagSizer:Add(TagsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
				\r\
				-- Tag List box, buttons and tree\r\
				local TagSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
					local TagListSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
						TagList = wx.wxListCtrl(PSandTag, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(0.1*GUI.initFrameW, 0.1*GUI.initFrameH),\r\
							bit.bor(wx.wxLC_REPORT,wx.wxLC_NO_HEADER,wx.wxLC_SINGLE_SEL))\r\
						-- Populate the tag list here\r\
						--local col = wx.wxListItem()\r\
						--col:SetId(0)\r\
						TagList:InsertColumn(0,\"Tags\")\r\
						if filterData.Tags then\r\
							for i=1,#filterData.Tags do\r\
								CW.InsertItem(TagList,filterData.Tags[i])\r\
							end\r\
						end\r\
						TagListSizer:Add(TagList, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
						TagCheckBox = wx.wxCheckBox(PSandTag, wx.wxID_ANY, \"None Also passes\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
						TagListSizer:Add(TagCheckBox, 0, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
						\r\
					TagSizer:Add(TagListSizer, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
					TagBoolCtrl = BooleanTreeCtrl(PSandTag,TagSizer,\r\
						function()\r\
							-- Return the selected item in Tag List\r\
							local item = TagList:GetNextItem(-1,wx.wxLIST_NEXT_ALL,wx.wxLIST_STATE_SELECTED)\r\
							if item == -1 then\r\
								return nil\r\
							else \r\
								return TagList:GetItemText(item)		\r\
							end\r\
						end, \r\
					\"Tags\")\r\
				PSandTagSizer:Add(TagSizer, 3, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
			PSandTag:SetSizer(PSandTagSizer)\r\
			PSandTagSizer:SetSizeHints(PSandTag)\r\
		MainBook:AddPage(PSandTag, \"Priorities,Status and Tags\")\r\
		\r\
		-- Date Started, Date Finished and Due Date Page\r\
		DatesPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			local DatesPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) \r\
			\r\
			-- Date Started Control\r\
			dateStarted = DateRangeCtrl(DatesPanel,\"Start\",false,\"Date Started\")\r\
			DatesPanelSizer:Add(dateStarted.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			-- Date Finished Control\r\
			dateFinished = DateRangeCtrl(DatesPanel,\"Fin\",true,\"Date Finished\")\r\
			DatesPanelSizer:Add(dateFinished.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			-- Due Date Control\r\
			dateDue = DateRangeCtrl(DatesPanel,\"Due\",true,\"Due Date\")\r\
			DatesPanelSizer:Add(dateDue.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			\r\
\r\
			DatesPanel:SetSizer(DatesPanelSizer)\r\
			DatesPanelSizer:SetSizeHints(DatesPanel)\r\
		MainBook:AddPage(DatesPanel, \"Dates:Due,Started,Finished\")\r\
\r\
		-- Who and Access IDs page\r\
		AccessPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			local AccessPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL)\r\
			\r\
			local whoSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
			local accSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) \r\
			\r\
			local whoLabel = wx.wxStaticText(AccessPanel, wx.wxID_ANY, \"Select Responsible People (Check means Inactive)\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
			AccessPanelSizer:Add(whoLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			\r\
			whoCtrl = CheckListCtrl(AccessPanel,false,\"I\",\"A\")\r\
			-- Populate the IDs\r\
			if filterData.Who then\r\
				for i = 1,#filterData.Who do\r\
					whoCtrl:InsertItem(filterData.Who[i], false)\r\
				end\r\
			end\r\
			whoSizer:Add(whoCtrl.Sizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
			WhoBoolCtrl = BooleanTreeCtrl(AccessPanel,whoSizer,whoCtrl:getSelectionFunc(), \"Who\")\r\
			AccessPanelSizer:Add(whoSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
			\r\
			local accLabel = wx.wxStaticText(AccessPanel, wx.wxID_ANY, \"Select People for access (Check means Read/Write Access)\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
			AccessPanelSizer:Add(accLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
			accCtrl = CheckListCtrl(AccessPanel,false,\"W\",\"R\")\r\
			-- Populate the IDs\r\
			if filterData.Access then\r\
				for i = 1,#filterData.Access do\r\
					accCtrl.InsertItem(accCtrl,filterData.Access[i], false)\r\
				end\r\
			end\r\
			accSizer:Add(accCtrl.Sizer,1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
			accBoolCtrl = BooleanTreeCtrl(AccessPanel,accSizer,accCtrl:getSelectionFunc(), \"Access\")\r\
			AccessPanelSizer:Add(accSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
\r\
			AccessPanel:SetSizer(AccessPanelSizer)\r\
			AccessPanelSizer:SetSizeHints(AccessPanel)\r\
		MainBook:AddPage(AccessPanel, \"Access\")\r\
		\r\
		-- Schedules Page\r\
		SchPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			local SchPanelSizer = wx.wxBoxSizer(wx.wxHORIZONTAL) \r\
			local duSizer = wx.wxBoxSizer(wx.wxVERTICAL)	-- Sizer for Date unit elements\r\
			\r\
			local typeMatchLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, \"Select Type of Matching\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
			duSizer:Add(typeMatchLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
			TypeMatch = wx.wxChoice(SchPanel, wx.wxID_ANY,wx.wxDefaultPosition, wx.wxDefaultSize,{\"Full\",\"Overlap\"})\r\
			duSizer:Add(TypeMatch,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
			TypeMatch:SetSelection(1)\r\
			\r\
			local typeSchLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, \"Select Type of Schedule\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
			duSizer:Add(typeSchLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
			TypeSch = wx.wxChoice(SchPanel, wx.wxID_ANY,wx.wxDefaultPosition, wx.wxDefaultSize,{\"Estimate\",\"Committed\",\"Revisions\",\"Actual\", \"Latest\"})\r\
			duSizer:Add(TypeSch,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
			TypeSch:SetSelection(2)\r\
						\r\
			local SchRevLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, \"Select Revision\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
			duSizer:Add(SchRevLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
\r\
			SchRev = wx.wxComboBox(SchPanel, wx.wxID_ANY,\"Latest\",wx.wxDefaultPosition, wx.wxDefaultSize,{\"Latest\"})\r\
			duSizer:Add(SchRev,0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
\r\
			-- Event connect to enable disable SchRev\r\
			TypeSch:Connect(wx.wxEVT_COMMAND_CHOICE_SELECTED,function(event) \r\
				setfenv(1,package.loaded[modname])\r\
				if TypeSch:GetString(TypeSch:GetSelection()) == \"Estimate\" or TypeSch:GetString(TypeSch:GetSelection()) == \"Revisions\" then\r\
					SchRev:Enable(true)\r\
				else\r\
					SchRev:Enable(false)\r\
				end\r\
			end \r\
			)\r\
\r\
			local DateRangeLabel = wx.wxStaticText(SchPanel, wx.wxID_ANY, \"Select Date Ranges\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE)\r\
			duSizer:Add(DateRangeLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			-- Date Ranges Control\r\
			schDateRanges = DateRangeCtrl(SchPanel,\"ScheduleRange\",true,\"Date Ranges\") \r\
			duSizer:Add(schDateRanges.Sizer,1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
			\r\
			SchPanelSizer:Add(duSizer, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
\r\
			-- Now add the Boolean Control\r\
			local getSchUnit = function()\r\
				-- Get the full schedule boolean unit\r\
				local unit = TypeMatch:GetString(TypeMatch:GetSelection())..\",\"..TypeSch:GetString(TypeSch:GetSelection())\r\
				if SchRev:IsEnabled() then\r\
					if SchRev:GetValue() == \"Latest\" then\r\
						unit = unit..\"(L)\"\r\
					else\r\
						unit = unit..\"(\"..tostring(SchRev:GetValue())..\")\"\r\
					end\r\
				end\r\
				schDateRanges:UpdateFilter()\r\
				if not filter.ScheduleRange then\r\
					unit = nil\r\
				else\r\
					unit = unit..\",\"..filter.ScheduleRange\r\
				end\r\
				return unit\r\
			end \r\
\r\
			SchBoolCtrl = BooleanTreeCtrl(SchPanel,SchPanelSizer,getSchUnit, \"Schedules\")\r\
\r\
			\r\
\r\
			SchPanel:SetSizer(SchPanelSizer)\r\
			SchPanelSizer:SetSizeHints(SchPanel)\r\
		MainBook:AddPage(SchPanel, \"Schedules\")\r\
		\r\
		-- Custom Script Entry Page\r\
		ScriptPanel = wx.wxPanel(MainBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL)\r\
			local ScriptPanelSizer = wx.wxBoxSizer(wx.wxVERTICAL) \r\
			\r\
			-- Text Instruction\r\
			local InsLabel = wx.wxStaticText(ScriptPanel, wx.wxID_ANY, \"Enter a custom script to filte out tasks additional to the Filter set in the form. The task would be present in the environment in the table called 'task'. Apart from that the environment is what is setup in Globals.safeenv. The 'result' variable should be updated to true if pass or false if does not pass.\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_LEFT)\r\
			InsLabel:Wrap(frame:GetSize():GetWidth()-25)\r\
			ScriptPanelSizer:Add(InsLabel, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
			ScriptBox = wx.wxTextCtrl(ScriptPanel, wx.wxID_ANY, \"\", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE)\r\
			ScriptPanelSizer:Add(ScriptBox, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL,wx.wxEXPAND), 1)\r\
			\r\
\r\
			ScriptPanel:SetSizer(ScriptPanelSizer)\r\
			ScriptPanelSizer:SetSizeHints(ScriptPanel)\r\
		MainBook:AddPage(ScriptPanel, \"Custom Script\")\r\
		\r\
\r\
	MainSizer:Add(MainBook, 1, bit.bor(wx.wxALL,wx.wxEXPAND,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	local ButtonSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)\r\
	ToBaseButton = wx.wxButton(frame, wx.wxID_ANY, \"Current to Base\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
	ButtonSizer:Add(ToBaseButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	CancelButton = wx.wxButton(frame, wx.wxID_ANY, \"Cancel\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
	ButtonSizer:Add(CancelButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	ApplyButton = wx.wxButton(frame, wx.wxID_ANY, \"Apply\", wx.wxDefaultPosition, wx.wxDefaultSize, 0, wx.wxDefaultValidator)\r\
	ButtonSizer:Add(ApplyButton, 1, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	MainSizer:Add(ButtonSizer, 0, bit.bor(wx.wxALL,wx.wxALIGN_CENTER_HORIZONTAL,wx.wxALIGN_CENTER_VERTICAL), 1)\r\
	frame:SetSizer(MainSizer)\r\
	--MainSizer:SetSizeHints(frame)\r\
	\r\
	-- Connect event handlers to the buttons\r\
	CancelButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function (event)\r\
			setfenv(1,package.loaded[modname])		\r\
			frame:Close()\r\
			callBack(nil)\r\
		end\r\
	)\r\
	\r\
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,\r\
		function (event)\r\
			setfenv(1,package.loaded[modname])		\r\
			event:Skip()\r\
			callBack(nil)\r\
		end\r\
	)\r\
\r\
	ApplyButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			local f = synthesizeFilter()\r\
			if not f then\r\
				return\r\
			end\r\
			--print(tableToString(f))\r\
			frame:Close()\r\
			callBack(f)\r\
		end		\r\
	)\r\
\r\
--	Connect(wxID_ANY,wxEVT_CLOSE_WINDOW,(wxObjectEventFunction)&CriteriaFrame::OnClose);\r\
\r\
	-- Task Selection/Clear button press event\r\
	SelTaskButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, SelTaskPress)\r\
	ClearTaskButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED,\r\
		function (event)\r\
			setfenv(1,package.loaded[modname])\r\
			filter.TasksSet = nil\r\
			FilterTask:SetLabel(\"No Task Selected\")\r\
		end\r\
	)\r\
	\r\
	frame:Connect(wx.wxEVT_SIZE,\r\
		function(event)\r\
			setfenv(1,package.loaded[modname])\r\
			InsLabel:Wrap(frame:GetSize():GetWidth())\r\
			event:Skip()\r\
		end\r\
	)\r\
\r\
	-- Toolbar button events\r\
	frame:Connect(ID_LOAD,wx.wxEVT_COMMAND_MENU_SELECTED,loadFilter)\r\
	frame:Connect(ID_SAVE,wx.wxEVT_COMMAND_MENU_SELECTED,saveFilter)\r\
	\r\
    frame:Layout() -- help sizing the windows before being shown\r\
    frame:Show(true)\r\
    setfilter(MainFilter)\r\
end		-- function filterFormActivate(parent) ends\r\
"
__MANY2ONEFILES['LuaXml']="require(\"LuaXML_lib\")\r\
\r\
local base = _G\r\
local xml = xml\r\
module(\"xml\")\r\
\r\
-- symbolic name for tag index, this allows accessing the tag by var[xml.TAG]\r\
TAG = 0\r\
\r\
-- sets or returns tag of a LuaXML object\r\
function tag(var,tag)\r\
  if base.type(var)~=\"table\" then return end\r\
  if base.type(tag)==\"nil\" then \r\
    return var[TAG]\r\
  end\r\
  var[TAG] = tag\r\
end\r\
\r\
-- creates a new LuaXML object either by setting the metatable of an existing Lua table or by setting its tag\r\
function new(arg)\r\
  if base.type(arg)==\"table\" then \r\
    base.setmetatable(arg,{__index=xml, __tostring=xml.str})\r\
	return arg\r\
  end\r\
  local var={}\r\
  base.setmetatable(var,{__index=xml, __tostring=xml.str})\r\
  if base.type(arg)==\"string\" then var[TAG]=arg end\r\
  return var\r\
end\r\
\r\
-- appends a new subordinate LuaXML object to an existing one, optionally sets tag\r\
function append(var,tag)\r\
  if base.type(var)~=\"table\" then return end\r\
  local newVar = new(tag)\r\
  var[#var+1] = newVar\r\
  return newVar\r\
end\r\
\r\
-- converts any Lua var into an XML string\r\
function str(var,indent,tagValue)\r\
  if base.type(var)==\"nil\" then return end\r\
  local indent = indent or 0\r\
  local indentStr=\"\"\r\
  for i = 1,indent do indentStr=indentStr..\"  \" end\r\
  local tableStr=\"\"\r\
  \r\
  if base.type(var)==\"table\" then\r\
    local tag = var[0] or tagValue or base.type(var)\r\
    local s = indentStr..\"<\"..tag\r\
    for k,v in base.pairs(var) do -- attributes \r\
      if base.type(k)==\"string\" then\r\
        if base.type(v)==\"table\" and k~=\"_M\" then --  otherwise recursiveness imminent\r\
          tableStr = tableStr..str(v,indent+1,k)\r\
        else\r\
          s = s..\" \"..k..\"=\\\"\"..encode(base.tostring(v))..\"\\\"\"\r\
        end\r\
      end\r\
    end\r\
    if #var==0 and #tableStr==0 then\r\
      s = s..\" />\\n\"\r\
    elseif #var==1 and base.type(var[1])~=\"table\" and #tableStr==0 then -- single element\r\
      s = s..\">\"..encode(base.tostring(var[1]))..\"</\"..tag..\">\\n\"\r\
    else\r\
      s = s..\">\\n\"\r\
      for k,v in base.ipairs(var) do -- elements\r\
        if base.type(v)==\"string\" then\r\
          s = s..indentStr..\"  \"..encode(v)..\" \\n\"\r\
        else\r\
          s = s..str(v,indent+1)\r\
        end\r\
      end\r\
      s=s..tableStr..indentStr..\"</\"..tag..\">\\n\"\r\
    end\r\
    return s\r\
  else\r\
    local tag = base.type(var)\r\
    return indentStr..\"<\"..tag..\"> \"..encode(base.tostring(var))..\" </\"..tag..\">\\n\"\r\
  end\r\
end\r\
\r\
\r\
-- saves a Lua var as xml file\r\
function save(var,filename)\r\
  if not var then return end\r\
  if not filename or #filename==0 then return end\r\
  local file = base.io.open(filename,\"w\")\r\
  file:write(\"<?xml version=\\\"1.0\\\"?>\\n<!-- file \\\"\",filename, \"\\\", generated by LuaXML -->\\n\\n\")\r\
  file:write(str(var))\r\
  base.io.close(file)\r\
end\r\
\r\
\r\
-- recursively parses a Lua table for a substatement fitting to the provided tag and attribute\r\
function find(var, tag, attributeKey,attributeValue)\r\
  -- check input:\r\
  if base.type(var)~=\"table\" then return end\r\
  if base.type(tag)==\"string\" and #tag==0 then tag=nil end\r\
  if base.type(attributeKey)~=\"string\" or #attributeKey==0 then attributeKey=nil end\r\
  if base.type(attributeValue)==\"string\" and #attributeValue==0 then attributeValue=nil end\r\
  -- compare this table:\r\
  if tag~=nil then\r\
    if var[0]==tag and ( attributeValue == nil or var[attributeKey]==attributeValue ) then\r\
      base.setmetatable(var,{__index=xml, __tostring=xml.str})\r\
      return var\r\
    end\r\
  else\r\
    if attributeValue == nil or var[attributeKey]==attributeValue then\r\
      base.setmetatable(var,{__index=xml, __tostring=xml.str})\r\
      return var\r\
    end\r\
  end\r\
  -- recursively parse subtags:\r\
  for k,v in base.ipairs(var) do\r\
    if base.type(v)==\"table\" then\r\
      local ret = find(v, tag, attributeKey,attributeValue)\r\
      if ret ~= nil then return ret end\r\
    end\r\
  end\r\
end\r\
"
__MANY2ONEFILES['DataHandler']="Karm.TaskObject = {}\r\
Karm.TaskObject.__index = Karm.TaskObject\r\
Karm.Utility = {}\r\
-- Task structure\r\
-- Task.\r\
--	Planning\r\
--	[0] = Task\r\
-- 	SporeFile\r\
--	Title\r\
--	Modified\r\
--	DBDATA\r\
--	TaskID\r\
--	Start\r\
--	Fin\r\
--	Private\r\
--	Who\r\
--	Access\r\
--	Assignee\r\
--	Status\r\
--	Parent = Pointer to the Task to which this is a sub task\r\
--	Priority\r\
--	Due\r\
--	Comments\r\
--	Cat\r\
--	SubCat\r\
--	Tags\r\
--	Schedules.\r\
--		[0] = \"Schedules\"\r\
--		Estimate.\r\
--			[0] = \"Estimate\"\r\
--			count\r\
--			[i] = \r\
--		Commit.\r\
--			[0] = \"Commit\"\r\
--		Revs\r\
--		Actual\r\
--	SubTasks.\r\
--		[0] = \"SubTasks\"\r\
--		parent  = pointer to the array containing the list of tasks having the task whose SubTask this is \r\
--		tasks = count of number of subtasks\r\
--		[i] = Task table like this one repeated for sub tasks\r\
function Karm.TaskObject.getSummary(task)\r\
	if task then\r\
		local taskSummary = \"\"\r\
		if task.TaskID then\r\
			taskSummary = \"ID: \"..task.TaskID\r\
		end\r\
		if task.Title then\r\
			taskSummary = taskSummary..\"\\nTITLE: \"..task.Title\r\
		end\r\
		if task.Start then\r\
			taskSummary = taskSummary..\"\\nSTART DATE: \"..task.Start\r\
		end\r\
		if task.Fin then\r\
			taskSummary = taskSummary..\"\\nFINISH DATE: \"..task.Fin\r\
		end\r\
		if task.Due then\r\
			taskSummary = taskSummary..\"\\nDUE DATE: \"..task.Due\r\
		end\r\
		if task.Status then\r\
			taskSummary = taskSummary..\"\\nSTATUS: \"..task.Status\r\
		end\r\
		-- Responsible People\r\
		if task.Who then\r\
			taskSummary = taskSummary..\"\\nPEOPLE: \"\r\
			local ACT = \"\"\r\
			local INACT = \"\"\r\
			for i=1,task.Who.count do\r\
				if string.upper(task.Who[i].Status) == \"ACTIVE\" then\r\
					ACT = ACT..\",\"..task.Who[i].ID\r\
				else\r\
					INACT = INACT..\",\"..task.Who[i].ID\r\
				end\r\
			end\r\
			if #ACT > 0 then\r\
				taskSummary = taskSummary..\"\\n   ACTIVE: \"..string.sub(ACT,2,-1)\r\
			end\r\
			if #INACT > 0 then\r\
				taskSummary = taskSummary..\"\\n   INACTIVE: \"..string.sub(INACT,2,-1)\r\
			end\r\
		end\r\
		if task.Access then\r\
			taskSummary = taskSummary..\"\\nLOCKED: YES\"\r\
			local RA = \"\"\r\
			local RWA = \"\"\r\
			for i = 1,task.Access.count do\r\
				if string.upper(task.Access[i].Status) == \"READ ONLY\" then\r\
					RA = RA..\",\"..task.Access[i].ID\r\
				else\r\
					RWA = RWA..\",\"..task.Access[i].ID\r\
				end\r\
			end\r\
			if #RA > 0 then\r\
				taskSummary = taskSummary..\"\\n   READ ACCESS PEOPLE: \"..string.sub(RA,2,-1)\r\
			end\r\
			if #RWA > 0 then\r\
				taskSummary = taskSummary..\"\\n   READ/WRITE ACCESS PEOPLE: \"..string.sub(RWA,2,-1)\r\
			end\r\
		end\r\
		if task.Assignee then\r\
			taskSummary = taskSummary..\"\\nASSIGNEE: \"\r\
			for i = 1,#task.Assignee do\r\
				taskSummary = taskSummary..task.Assignee[i].ID..\",\"\r\
			end\r\
			taskSummary = taskSummary:sub(1,-2)\r\
		end\r\
		if task.Priority then\r\
			taskSummary = taskSummary..\"\\nPRIORITY: \"..task.Priority\r\
		end\r\
		if task.Private then\r\
			taskSummary = taskSummary..\"\\nPRIVATE TASK\"\r\
		end\r\
		if task.Cat then\r\
			taskSummary = taskSummary..\"\\nCATEGORY: \"..task.Cat\r\
		end\r\
		if task.SubCat then\r\
			taskSummary = taskSummary..\"\\nSUB-CATEGORY: \"..task.SubCat\r\
		end\r\
		if task.Tags then\r\
			taskSummary = taskSummary..\"\\nTAGS: \"\r\
			for i = 1,#task.Tags do\r\
				taskSummary = taskSummary..task.Tags[i]..\",\"\r\
			end\r\
			taskSummary = taskSummary:sub(1,-2)\r\
		end\r\
		if task.Comments then\r\
			taskSummary = taskSummary..\"\\nCOMMENTS:\\n\"..task.Comments\r\
		end\r\
		return taskSummary\r\
	else\r\
		return \"No Task Selected\"\r\
	end\r\
end\r\
\r\
function Karm.validateSpore(Spore)\r\
	if not Spore then\r\
		return nil\r\
	elseif type(Spore) ~= \"table\" then\r\
		return nil\r\
	elseif Spore[0] ~= \"Task_Spore\" then\r\
		return nil\r\
	end\r\
	return true\r\
end\r\
\r\
\r\
function Karm.TaskObject.getWorkDoneDates(task)\r\
	if task.Schedules then\r\
		if task.Schedules.Actual then\r\
			local dateList = {}\r\
			for i = 1,#task.Schedules[\"Actual\"][1].Period do\r\
				dateList[#dateList + 1] = task.Schedules[\"Actual\"][1].Period[i].Date\r\
			end		-- for i = 1,#task.Schedules[\"Actual\"][1].Period do ends\r\
			dateList.typeSchedule = \"Actual\"\r\
			dateList.index = 1\r\
			return dateList\r\
		else \r\
			return nil\r\
		end\r\
	else \r\
		return nil		\r\
	end		-- if task.Schedules then ends\r\
end\r\
-- Function to get the list of dates in the latest schedule of the task.\r\
-- if planning == true then the planning schedule dates are returned\r\
function Karm.TaskObject.getLatestScheduleDates(task,planning)\r\
	local typeSchedule, index\r\
	local dateList = {}\r\
	if planning then\r\
		if task.Planning and task.Planning.Period then\r\
			for i = 1,#task.Planning.Period do\r\
				dateList[#dateList + 1] = task.Planning.Period[i].Date\r\
			end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends\r\
			dateList.typeSchedule = task.Planning.Type\r\
			dateList.index = task.Planning.index\r\
			return dateList\r\
		else\r\
			return nil\r\
		end\r\
	else\r\
		if task.Schedules then\r\
			-- Find the latest schedule in the task here\r\
			if string.upper(task.Status) == \"DONE\" and task.Schedules.Actual then\r\
				typeSchedule = \"Actual\"\r\
				index = 1\r\
			elseif task.Schedules.Revs then\r\
				-- Actual is not the latest one but Revision is \r\
				typeSchedule = \"Revs\"\r\
				index = task.Schedules.Revs.count\r\
			elseif task.Schedules.Commit then\r\
				-- Actual and Revisions don't exist but Commit does\r\
				typeSchedule = \"Commit\"\r\
				index = 1\r\
			elseif task.Schedules.Estimate then\r\
				-- The latest is Estimate\r\
				typeSchedule = \"Estimate\"\r\
				index = task.Schedules.Estimate.count\r\
			else\r\
				-- task.Schedules can exist if only Actual exists  but task is not DONE yet\r\
				return nil\r\
			end\r\
			-- Now we have the latest schedule type in typeSchedule and the index of it in index\r\
			for i = 1,#task.Schedules[typeSchedule][index].Period do\r\
				dateList[#dateList + 1] = task.Schedules[typeSchedule][index].Period[i].Date\r\
			end		-- for i = 1,#task.Schedules[typeSchedule][index].Period do ends\r\
			dateList.typeSchedule = typeSchedule\r\
			dateList.index = index\r\
			return dateList\r\
		else\r\
			return nil\r\
		end\r\
	end		-- if planning then ends\r\
end\r\
\r\
-- Function to convert a table to a string\r\
-- Metatables not followed\r\
-- Unless key is a number it will be taken and converted to a string\r\
function Karm.Utility.tableToString(t)\r\
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)\r\
	rL[rL.cL] = {}\r\
	do\r\
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)\r\
		rL[rL.cL].str = \"{\"\r\
		rL[rL.cL].t = t\r\
		while true do\r\
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)\r\
			rL[rL.cL]._var = k\r\
			if not k and rL.cL == 1 then\r\
				break\r\
			elseif not k then\r\
				-- go up in recursion level\r\
				if string.sub(rL[rL.cL].str,-1,-1) == \",\" then\r\
					rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)\r\
				end\r\
				--print(\"GOING UP:     \"..rL[rL.cL].str..\"}\")\r\
				rL[rL.cL-1].str = rL[rL.cL-1].str..rL[rL.cL].str..\"}\"\r\
				rL.cL = rL.cL - 1\r\
				rL[rL.cL+1] = nil\r\
				rL[rL.cL].str = rL[rL.cL].str..\",\"\r\
			else\r\
				-- Handle the key and value here\r\
				if type(k) == \"number\" then\r\
					rL[rL.cL].str = rL[rL.cL].str..\"[\"..tostring(k)..\"]=\"\r\
				else\r\
					rL[rL.cL].str = rL[rL.cL].str..tostring(k)..\"=\"\r\
				end\r\
				if type(v) == \"table\" then\r\
					-- Check if this is not a recursive table\r\
					local goDown = true\r\
					for i = 1, rL.cL do\r\
						if v==rL[i].t then\r\
							-- This is recursive do not go down\r\
							goDown = false\r\
							break\r\
						end\r\
					end\r\
					if goDown then\r\
						-- Go deeper in recursion\r\
						rL.cL = rL.cL + 1\r\
						rL[rL.cL] = {}\r\
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)\r\
						rL[rL.cL].str = \"{\"\r\
						rL[rL.cL].t = v\r\
						--print(\"GOING DOWN:\",k)\r\
					else\r\
						rL[rL.cL].str = rL[rL.cL].str..\"\\\"\"..tostring(v)..\"\\\"\"\r\
						rL[rL.cL].str = rL[rL.cL].str..\",\"\r\
						--print(k,\"=\",v)\r\
					end\r\
				elseif type(v) == \"number\" then\r\
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)\r\
					rL[rL.cL].str = rL[rL.cL].str..\",\"\r\
					--print(k,\"=\",v)\r\
				else\r\
					rL[rL.cL].str = rL[rL.cL].str..string.format(\"%q\",tostring(v))\r\
					rL[rL.cL].str = rL[rL.cL].str..\",\"\r\
					--print(k,\"=\",v)\r\
				end		-- if type(v) == \"table\" then ends\r\
			end		-- if not rL[rL.cL]._var and rL.cL == 1 then ends\r\
		end		-- while true ends here\r\
	end		-- do ends\r\
	if string.sub(rL[rL.cL].str,-1,-1) == \",\" then\r\
		rL[rL.cL].str = string.sub(rL[rL.cL].str,1,-2)\r\
	end\r\
	rL[rL.cL].str = rL[rL.cL].str..\"}\"\r\
	return rL[rL.cL].str\r\
end\r\
\r\
-- Creates lua code for a table which when executed will create a table t0 which would be the same as the originally passed table\r\
-- Handles the following types for keys and values:\r\
-- Keys: Number, String, Table\r\
-- Values: Number, String, Table, Boolean\r\
-- It also handles recursive and interlinked tables to recreate them back\r\
function Karm.Utility.tableToString2(t)\r\
	local rL = {cL = 1}	-- Table to track recursion into nested tables (cL = current recursion level)\r\
	rL[rL.cL] = {}\r\
	local tabIndex = {}	-- Table to store a list of tables indexed into a string and their variable name\r\
	local latestTab = 0\r\
	do\r\
		rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(t)\r\
		rL[rL.cL].str = \"t0={}\"	-- t0 would be the main table\r\
		rL[rL.cL].t = t\r\
		rL[rL.cL].tabIndex = 0\r\
		tabIndex[t] = rL[rL.cL].tabIndex\r\
		while true do\r\
			local key\r\
			local k,v = rL[rL.cL]._f(rL[rL.cL]._s,rL[rL.cL]._var)\r\
			rL[rL.cL]._var = k\r\
			if not k and rL.cL == 1 then\r\
				break\r\
			elseif not k then\r\
				-- go up in recursion level\r\
				--print(\"GOING UP:     \"..rL[rL.cL].str..\"}\")\r\
				rL[rL.cL-1].str = rL[rL.cL-1].str..\"\\n\"..rL[rL.cL].str\r\
				rL.cL = rL.cL - 1\r\
				if rL[rL.cL].vNotDone then\r\
					-- This was a key recursion so add the key string and then doV\r\
					key = \"t\"..rL[rL.cL].tabIndex..\"[t\"..tostring(rL[rL.cL+1].tabIndex)..\"]\"\r\
					rL[rL.cL].str = rL[rL.cL].str..\"\\n\"..key..\"=\"\r\
					v = rL[rL.cL].vNotDone\r\
				end\r\
				rL[rL.cL+1] = nil\r\
			else\r\
				-- Handle the key and value here\r\
				if type(k) == \"number\" then\r\
					key = \"t\"..rL[rL.cL].tabIndex..\"[\"..tostring(k)..\"]\"\r\
					rL[rL.cL].str = rL[rL.cL].str..\"\\n\"..key..\"=\"\r\
				elseif type(k) == \"string\" then\r\
					key = \"t\"..rL[rL.cL].tabIndex..\".\"..tostring(k)\r\
					rL[rL.cL].str = rL[rL.cL].str..\"\\n\"..key..\"=\"\r\
				else\r\
					-- Table key\r\
					-- Check if the table already exists\r\
					if tabIndex[k] then\r\
						key = \"t\"..rL[rL.cL].tabIndex..\"[t\"..tabIndex[k]..\"]\"\r\
						rL[rL.cL].str = rL[rL.cL].str..\"\\n\"..key..\"=\"\r\
					else\r\
						-- Go deeper to stringify this table\r\
						latestTab = latestTab + 1\r\
						rL[rL.cL].str = rL[rL.cL].str..\"\\nt\"..tostring(latestTab)..\"={}\"	-- New table\r\
						rL[rL.cL].vNotDone = v\r\
						rL.cL = rL.cL + 1\r\
						rL[rL.cL] = {}\r\
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(k)\r\
						rL[rL.cL].tabIndex = latestTab\r\
						rL[rL.cL].t = k\r\
						rL[rL.cL].str = \"\"\r\
						tabIndex[k] = rL[rL.cL].tabIndex\r\
					end		-- if tabIndex[k] then ends\r\
				end		-- if type(k)ends\r\
			end		-- if not k and rL.cL == 1 then ends\r\
			if key then\r\
				rL[rL.cL].vNotDone = nil\r\
				if type(v) == \"table\" then\r\
					-- Check if this table is already indexed\r\
					if tabIndex[v] then\r\
						rL[rL.cL].str = rL[rL.cL].str..\"t\"..tabIndex[v]\r\
					else\r\
						-- Go deeper in recursion\r\
						latestTab = latestTab + 1\r\
						rL[rL.cL].str = rL[rL.cL].str..\"{}\" \r\
						rL[rL.cL].str = rL[rL.cL].str..\"\\nt\"..tostring(latestTab)..\"=\"..key	-- New table\r\
						rL.cL = rL.cL + 1\r\
						rL[rL.cL] = {}\r\
						rL[rL.cL]._f,rL[rL.cL]._s,rL[rL.cL]._var = pairs(v)\r\
						rL[rL.cL].tabIndex = latestTab\r\
						rL[rL.cL].t = v\r\
						rL[rL.cL].str = \"\"\r\
						tabIndex[v] = rL[rL.cL].tabIndex\r\
						--print(\"GOING DOWN:\",k)\r\
					end\r\
				elseif type(v) == \"number\" then\r\
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)\r\
					--print(k,\"=\",v)\r\
				elseif type(v) == \"boolean\" then\r\
					rL[rL.cL].str = rL[rL.cL].str..tostring(v)				\r\
				else\r\
					rL[rL.cL].str = rL[rL.cL].str..string.format(\"%q\",tostring(v))\r\
					--print(k,\"=\",v)\r\
				end		-- if type(v) == \"table\" then ends\r\
			end		-- if doV then ends\r\
		end		-- while true ends here\r\
	end		-- do ends\r\
	return rL[rL.cL].str\r\
end\r\
\r\
function Karm.Utility.combineDateRanges(range1,range2)\r\
	local comp = Karm.Utility.compareDateRanges(range1,range2)\r\
\r\
	local strt1,fin1 = string.match(range1,\"(.-)%-(.*)\")\r\
	local strt2,fin2 = string.match(range2,\"(.-)%-(.*)\")\r\
	\r\
	strt1 = Karm.Utility.toXMLDate(strt1)\r\
	local idate = Karm.Utility.XMLDate2wxDateTime(strt1)\r\
	idate = idate:Subtract(wx.wxDateSpan(0,0,0,1))\r\
	local strt1m1 = Karm.Utility.toXMLDate(idate:Format(\"%m/%d/%Y\"))\r\
	\r\
	fin1 = Karm.Utility.toXMLDate(fin1)\r\
	idate = Karm.Utility.XMLDate2wxDateTime(fin1)\r\
	idate = idate:Add(wx.wxDateSpan(0,0,0,1))\r\
	local fin1p1 = Karm.Utility.toXMLDate(idate:Format(\"%m/%d/%Y\"))\r\
\r\
	strt2 = Karm.Utility.toXMLDate(strt2)\r\
\r\
	fin2 = Karm.Utility.toXMLDate(fin2)\r\
\r\
	if comp == 1 then\r\
		return range1\r\
	elseif comp==2 then\r\
		-- range1 lies entirely before range2\r\
		error(\"Disjoint ranges\",2)\r\
	elseif comp==3 then\r\
		-- range1 pre-overlaps range2\r\
		return string.sub(strt1,6,7)..\"/\"..string.sub(strt1,-2,-1)..\"/\"..string.sub(strt1,1,4)..\"-\"..\r\
			string.sub(fin2,6,7)..\"/\"..string.sub(fin2,-2,-1)..\"/\"..string.sub(fin2,1,4)\r\
	elseif comp==4 then\r\
		-- range1 lies entirely inside range2\r\
		return range2\r\
	elseif comp==5 then\r\
		-- range1 post overlaps range2\r\
		return string.sub(strt2,6,7)..\"/\"..string.sub(strt2,-2,-1)..\"/\"..string.sub(strt2,1,4)..\"-\"..\r\
			string.sub(fin1,6,7)..\"/\"..string.sub(fin1,-2,-1)..\"/\"..string.sub(fin1,1,4)\r\
	elseif comp==6 then\r\
		-- range1 lies entirely after range2\r\
		error(\"Disjoint ranges\",2)\r\
	elseif comp==7 then\r\
		-- range2 lies entirely inside range1\r\
			return range1\r\
	end		\r\
end\r\
\r\
function Karm.Utility.XMLDate2wxDateTime(XMLdate)\r\
	local map = {\r\
		[1] = wx.wxDateTime.Jan,\r\
		[2] = wx.wxDateTime.Feb,\r\
		[3] = wx.wxDateTime.Mar,\r\
		[4] = wx.wxDateTime.Apr,\r\
		[5] = wx.wxDateTime.May,\r\
		[6] = wx.wxDateTime.Jun,\r\
		[7] = wx.wxDateTime.Jul,\r\
		[8] = wx.wxDateTime.Aug,\r\
		[9] = wx.wxDateTime.Sep,\r\
		[10] = wx.wxDateTime.Oct,\r\
		[11] = wx.wxDateTime.Nov,\r\
		[12] = wx.wxDateTime.Dec\r\
	}\r\
	return wx.wxDateTimeFromDMY(tonumber(string.sub(XMLdate,-2,-1)),map[tonumber(string.sub(XMLdate,6,7))],tonumber(string.sub(XMLdate,1,4)))\r\
end\r\
\r\
--****f* Karm/compareDateRanges\r\
-- FUNCTION\r\
-- Function to compare 2 date ranges\r\
-- \r\
-- INPUT\r\
-- o range1 -- Date Range 1 eg. 2/25/2012-2/27/2012\r\
-- o range2 -- Date Range 2 eg. 2/25/2012-3/27/2012\r\
-- \r\
-- RETURNS\r\
-- o 1 -- If date ranges identical\r\
-- o 2 -- If range1 lies entirely before range2\r\
-- o 3 -- If range1 pre-overlaps range2 i.e. start date of range 1 is < start date of range 2 and end date of range1 is <= end date of range2 and not condition 2\r\
-- o 4 -- If range1 lies entirely inside range2\r\
-- o 5 -- If range1 post overlaps range2 i.e. start date of range 1 >= start date of range 2 and start date of range 1 - 1 day <= end date of range 2 and not condition 4 \r\
-- o 6 -- If range1 lies entirely after range2\r\
-- o 7 -- If range2 lies entirely inside range1\r\
-- o nil -- for error\r\
--\r\
-- SOURCE\r\
function Karm.Utility.compareDateRanges(range1,range2)\r\
--@@END@@\r\
	if not(range1 and range2) or range1==\"\" or range2==\"\" then\r\
		error(\"Expected a valid date range.\",2)\r\
	end\r\
	\r\
	if range1 == range2 then\r\
		--  date ranges identical\r\
		return 1\r\
	end\r\
	\r\
	local strt1,fin1 = string.match(range1,\"(.-)%-(.*)\")\r\
	local strt2,fin2 = string.match(range2,\"(.-)%-(.*)\")\r\
	\r\
	strt1 = Karm.Utility.toXMLDate(strt1)\r\
	local idate = Karm.Utility.XMLDate2wxDateTime(strt1)\r\
	idate = idate:Subtract(wx.wxDateSpan(0,0,0,1))\r\
	local strt1m1 = Karm.Utility.toXMLDate(idate:Format(\"%m/%d/%Y\"))\r\
	\r\
	fin1 = Karm.Utility.toXMLDate(fin1)\r\
	idate = Karm.Utility.XMLDate2wxDateTime(fin1)\r\
	idate = idate:Add(wx.wxDateSpan(0,0,0,1))\r\
	local fin1p1 = Karm.Utility.toXMLDate(idate:Format(\"%m/%d/%Y\"))\r\
	\r\
	strt2 = Karm.Utility.toXMLDate(strt2)\r\
	\r\
	fin2 = Karm.Utility.toXMLDate(fin2)\r\
	\r\
	if strt1>fin1 or strt2>fin2 then\r\
		error(\"Range given is not valid. Start date should be less than finish date.\",2)\r\
	end\r\
	\r\
	if fin1p1<strt2 then\r\
		-- range1 lies entirely before range2\r\
		return 2\r\
	elseif fin1<=fin2 and strt1<strt2 then\r\
		-- range1 pre-overlaps range2\r\
		return 3\r\
	elseif strt1>strt2 and fin1<fin2 then\r\
		-- range1 lies entirely inside range2\r\
		return 4\r\
	elseif strt1m1<=fin2 and strt1>=strt2 then\r\
		-- range1 post overlaps range2\r\
		return 5\r\
	elseif strt1m1>fin2 then\r\
		-- range1 lies entirely after range2\r\
		return 6\r\
	elseif strt1<strt2 and fin1>fin2 then\r\
		-- range2 lies entirely inside range1\r\
		return 7\r\
	end\r\
end\r\
--****f* Karm/ToXMLDate\r\
-- FUNCTION\r\
-- Function to convert display format date to XML format date YYYY-MM-DD\r\
-- display date format is MM/DD/YYYY\r\
--\r\
-- INPUT\r\
-- o displayDate -- String variable containing the date string as MM/DD/YYYY\r\
--\r\
-- RETURNS\r\
-- The date as a string compliant to XML date format YYYY-MM-DD\r\
--\r\
-- SOURCE\r\
function Karm.Utility.toXMLDate(displayDate)\r\
--@@END@@\r\
\r\
    local exYear, exMonth, exDate\r\
    local count = 1\r\
    for num in string.gmatch(displayDate,\"%d+\") do\r\
    	if count == 1 then\r\
    		-- this is month\r\
    		exMonth = num\r\
	    	if #exMonth == 1 then\r\
        		exMonth = \"0\" .. exMonth\r\
        	end\r\
        elseif count==2 then\r\
        	-- this is the date\r\
        	exDate = num\r\
        	if #exDate == 1 then\r\
        		exDate = \"0\" .. exDate\r\
        	end\r\
        elseif count== 3 then\r\
        	-- this is the year\r\
        	exYear = num\r\
        	if #exYear == 1 then\r\
        		exYear = \"000\" .. exYear\r\
        	elseif #exYear == 2 then\r\
        		exYear = \"00\" .. exYear\r\
        	elseif #exYear == 3 then\r\
        		exYear = \"0\" .. exYear\r\
        	end\r\
        end\r\
        count = count + 1\r\
	end    \r\
    return exYear .. \"-\" .. exMonth .. \"-\" .. exDate\r\
end\r\
\r\
function Karm.Utility.getWeekDay(xmlDate)\r\
	if #xmlDate ~= 10 then\r\
		error(\"Expected XML Date in the form YYYY-MM-DD\",2)\r\
	end\r\
	local WeekDays = {\"Sunday\",\"Monday\",\"Tuesday\",\"Wednesday\",\"Thursday\",\"Friday\",\"Saturday\"}\r\
	-- Using the Gauss Formula\r\
	-- http://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week#Gaussian_algorithm\r\
	local d = tonumber(xmlDate:sub(-2,-1))\r\
	local m = tonumber(xmlDate:sub(6,7))\r\
	m = (m + 9)%12 + 1\r\
	local Y\r\
	if m > 10 then\r\
		Y = string.match(tostring(tonumber(xmlDate:sub(1,4)) - 1),\"%d+\")\r\
		Y = string.rep(\"0\",4-#Y)..Y\r\
	else\r\
		Y = xmlDate:sub(1,4)\r\
	end\r\
	local y = tonumber(Y:sub(-2,-1))\r\
	local c = tonumber(Y:sub(1,2))\r\
	local w = (d + (2.6*m-0.2)-(2.6*m-0.2)%1 + y + (y/4)-(y/4)%1 + (c/4)-(c/4)%1-2*c)%7+1\r\
	return WeekDays[w]\r\
end\r\
\r\
function Karm.Utility.addItemToArray(item,array)\r\
	local pos = 0\r\
	for i = 1,#array do\r\
		if array[i] == item  then\r\
			return array\r\
		end\r\
		if array[i]>item then\r\
			pos = i\r\
			break\r\
		end\r\
	end\r\
	if pos == 0 then\r\
		-- place item in the end\r\
		array[#array+1] = item\r\
		return array\r\
	end\r\
	local newarray = {}\r\
	for i = 1,pos-1 do\r\
		newarray[i] = array[i]\r\
	end\r\
	newarray[pos] = item\r\
	for i = pos,#array do\r\
		newarray[i+1] = array[i]\r\
	end\r\
	return newarray\r\
end\r\
\r\
-- Function to apply a function to a task and its hierarchy\r\
-- The function should have the task as the 1st argument \r\
-- and whatever it returns is passed to it it as the 2nd argument in the next call to it with the next task\r\
-- In the 1st call the second argument is passed if it is given as the 3rd argument to this function\r\
-- The last return from the function is returned by this function\r\
-- if omitTask is true then the func is not run for the task itself and it starts from the subTasks\r\
function Karm.TaskObject.applyFuncHier(task, func, initialValue, omitTask)\r\
	local passedVar	= initialValue	-- Variable passed to the function\r\
	if not omitTask then\r\
		passedVar = func(task,initialValue)\r\
	end\r\
	if task.SubTasks then\r\
		-- Traverse the task hierarchy here\r\
		local hier = task.SubTasks\r\
		local hierCount = {}\r\
		hierCount[hier] = 0\r\
		while hierCount[hier] < #hier or hier.parent do\r\
			if not(hierCount[hier] < #hier) then\r\
				if hier == task.SubTasks then\r\
					-- Do not go above the passed task\r\
					break\r\
				end \r\
				hier = hier.parent\r\
			else\r\
				-- Increment the counter\r\
				hierCount[hier] = hierCount[hier] + 1\r\
				passedVar = func(hier[hierCount[hier]],passedVar)\r\
				if hier[hierCount[hier]].SubTasks then\r\
					-- This task has children so go deeper in the hierarchy\r\
					hier = hier[hierCount[hier]].SubTasks\r\
					hierCount[hier] = 0\r\
				end\r\
			end\r\
		end		-- while hierCount[hier] < #hier or hier.parent do ends here\r\
	end\r\
	return passedVar\r\
end\r\
\r\
-- Function to get a next task (from the given task) in the task hierarchy. After all tasks for a spore are finished then it will return a nil\r\
-- Traversal is in the order as if listing out the tasks for a fully expanded task tree\r\
function Karm.TaskObject.NextInSequence(task)\r\
	if not task then\r\
		error(\"Need a task object to give the next task\", 2)\r\
	end\r\
	if not type(task) == \"table\" then\r\
		error(\"Need a task object to give the next task\", 2)\r\
	end\r\
	if task.SubTasks and task.SubTasks[1] then\r\
		return task.SubTasks[1]\r\
	end	\r\
	if task.Next then\r\
		return task.Next\r\
	end\r\
	if task.Parent then\r\
		local currTask = task.Parent\r\
		if currTask.Next then\r\
			return currTask.Next\r\
		end\r\
		while currTask.Parent do\r\
			currTask = currTask.Parent\r\
			if currTask.Next then\r\
				return currTask.Next\r\
			end\r\
		end\r\
	end\r\
end\r\
\r\
-- Function to get a next task (from the given task) in the task hierarchy. After all tasks for a spore are finished then it will return a nil\r\
-- Traversal is in the order as if listing out the tasks for a fully expanded task tree\r\
function Karm.TaskObject.PreviousInSequence(task)\r\
	if not task then\r\
		error(\"Need a task object to give the next task\", 2)\r\
	end\r\
	if not type(task) == \"table\" then\r\
		error(\"Need a task object to give the next task\", 2)\r\
	end\r\
	if task.Previous then\r\
		local currTask = task.Previous\r\
		while Karm.TaskObject.NextInSequence(currTask) ~= task do\r\
			currTask = Karm.TaskObject.NextInSequence(currTask)\r\
		end\r\
		return currTask\r\
	end\r\
	return task.Parent\r\
end\r\
\r\
function Karm.TaskObject.accumulateTaskData(task,Data)\r\
	Data = Data or {}\r\
	Data.Who = Data.Who or {}\r\
	Data.Access = Data.Access or {}\r\
	Data.Priority = Data.Priority or {}\r\
	Data.Cat = Data.Cat or {}\r\
	Data.SubCat = Data.SubCat or {}\r\
	Data.Tags = Data.Tags or {}\r\
	-- Who data\r\
	for i = 1,#task.Who do\r\
		Data.Who = Karm.Utility.addItemToArray(task.Who[i].ID,Data.Who)\r\
	end\r\
	-- Access Data\r\
	if task.Access then\r\
		for i = 1,#task.Access do\r\
			Data.Access = Karm.Utility.addItemToArray(task.Access[i].ID,Data.Access)\r\
		end\r\
	end\r\
	-- Priority Data\r\
	if task.Priority then\r\
		Data.Priority = Karm.Utility.addItemToArray(task.Priority,Data.Priority)\r\
	end			\r\
	-- Category Data\r\
	if task.Cat then\r\
		Data.Cat = Karm.Utility.addItemToArray(task.Cat,Data.Cat)\r\
	end			\r\
	-- Sub-Category Data\r\
	if task.SubCat then\r\
		Data.SubCat = Karm.Utility.addItemToArray(task.SubCat,Data.SubCat)\r\
	end			\r\
	-- Tags Data\r\
	if task.Tags then\r\
		for i = 1,#task.Tags do\r\
			Data.Tags = Karm.Utility.addItemToArray(task.Tags[i],Data.Tags)\r\
		end\r\
	end\r\
	return Data\r\
end\r\
\r\
\r\
-- Function to collect and return all data from the task heirarchy on the basis of which task filtration criteria can be selected\r\
function Karm.accumulateTaskDataHier(filterData, taskHier)\r\
	local hier = taskHier\r\
	-- Reset the hierarchy if not already done so\r\
	while hier.parent do\r\
		hier = hier.parent\r\
	end\r\
	for i = 1,#hier do\r\
		filterData = Karm.TaskObject.applyFuncHier(hier[i],Karm.TaskObject.accumulateTaskData,filterData)\r\
	end\r\
end\r\
\r\
-- Old version \r\
--function Karm.accumulateTaskDataHier(filterData, taskHier)\r\
--	local hier = taskHier\r\
--	local hierCount = {}\r\
--	-- Reset the hierarchy if not already done so\r\
--	while hier.parent do\r\
--		hier = hier.parent\r\
--	end\r\
--	-- Traverse the task hierarchy here\r\
--	hierCount[hier] = 0\r\
--	while hierCount[hier] < #hier or hier.parent do\r\
--		if not(hierCount[hier] < #hier) then\r\
--			if hier == taskHier then\r\
--				-- Do not go above the passed task\r\
--				break\r\
--			end \r\
--			hier = hier.parent\r\
--		else\r\
--			-- Increment the counter\r\
--			hierCount[hier] = hierCount[hier] + 1\r\
--			Karm.TaskObject.accumulateTaskData(hier[hierCount[hier]],filterData)\r\
--			if hier[hierCount[hier]].SubTasks then\r\
--				-- This task has children so go deeper in the hierarchy\r\
--				hier = hier[hierCount[hier]].SubTasks\r\
--				hierCount[hier] = 0\r\
--			end\r\
--		end\r\
--	end		-- while hierCount[hier] < #hier or hier.parent do ends here\r\
--end\r\
\r\
function Karm.accumulateTaskDataList(filterData,taskList)\r\
	for i=1,#taskList do\r\
		Karm.TaskObject.accumulateTaskData(taskList[i],filterData)\r\
	end\r\
end\r\
\r\
-- Function to make a copy of a task\r\
-- Each task has at most 9 tables:\r\
-- Who\r\
-- Access\r\
-- Assignee\r\
-- Schedules\r\
-- Tags\r\
-- Parent\r\
-- SubTasks\r\
-- DBDATA\r\
-- Planning  \r\
\r\
-- 1st 5 are made a copy of\r\
-- Parent is the same linked tables\r\
-- If copySubTasks is true then SubTasks are made a copy as well with the same parameters otherwise it is the same linked SubTask table\r\
-- If removeDBDATA is true then it removes the DBDATA table to make this an individual task otherwise it is the same linked table\r\
-- Normally the task parents are linked to the tasks from which the hierarchy is being copied over, if keepOldTaskParents is false then all the task parents\r\
-- in the copied hierarchy (excluding this task) will be updated to point to the copied hierarchy tasks\r\
-- Planning is not copied over\r\
function Karm.TaskObject.copy(task, copySubTasks, removeDBDATA,keepOldTaskParents)\r\
	-- Copied from http://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value\r\
	local copyTableFunc\r\
	local function copyTable(t, deep, seen)\r\
	    seen = seen or {}\r\
	    if t == nil then return nil end\r\
	    if seen[t] then return seen[t] end\r\
	\r\
	    local nt = {}\r\
	    for k, v in pairs(t) do\r\
	        if deep and type(v) == 'table' then\r\
	            nt[k] = copyTableFunc(v, deep, seen)\r\
	        else\r\
	            nt[k] = v\r\
	        end\r\
	    end\r\
	    setmetatable(nt, copyTableFunc(getmetatable(t), deep, seen))\r\
	    seen[t] = nt\r\
	    return nt\r\
	end\r\
	copyTableFunc = copyTable\r\
\r\
	if not task then\r\
		return\r\
	end\r\
	local nTask = {}\r\
	for k,v in pairs(task) do\r\
		if k ~= \"Planning\" and not (k == \"DBDATA\" and removeDBDATA)then\r\
			if k ~= \"Who\" and k ~= \"Schedules\" and k~= \"Tags\" and k ~= \"Access\" and k ~= \"Assignee\" and not (k == \"SubTasks\" and copySubTasks)then\r\
				nTask[k] = task[k]\r\
			else\r\
				if k == \"SubTasks\" then\r\
					-- This has to be copied in 2 steps\r\
					local parent\r\
					if task.Parent then\r\
						parent = task.Parent.SubTasks\r\
					else\r\
						-- Must be a root node in a Spore so take the Spore table as the parent itself\r\
						parent = task.SubTasks.parent\r\
					end\r\
					nTask.SubTasks = {parent = parent, tasks = #task.SubTasks, [0]=\"SubTasks\"}\r\
					for i = 1,#task.SubTasks do\r\
						nTask.SubTasks[i] = Karm.TaskObject.copy(task.SubTasks[i],true,removeDBDATA,true)\r\
					end\r\
				else\r\
					nTask[k] = copyTable(task[k],true)\r\
				end\r\
			end\r\
		end\r\
	end		-- for k,v in pairs(task) do ends\r\
	if not keepOldTaskParents and nTask.SubTasks then\r\
		-- Correct for the task parents of all subtasks\r\
		Karm.TaskObject.applyFuncHier(nTask,function(task, subTaskParent)\r\
								if task.SubTasks then\r\
									if subTaskParent then\r\
										task.SubTasks.parent = task.Parent.SubTasks\r\
									end\r\
									for i = 1,#task.SubTasks do\r\
										task.SubTasks[i].Parent = task\r\
									end\r\
								end\r\
								return true\r\
							end\r\
		)\r\
	end\r\
	Karm.TaskObject.MakeTaskObject(nTask)\r\
	return nTask\r\
end		-- function Karm.TaskObject.copy(task)ends\r\
\r\
function Karm.TaskObject.MakeTaskObject(task)\r\
	setmetatable(task,Karm.TaskObject)\r\
end\r\
\r\
-- Function to convert a task to a task list with incremental schedules i.e. 1st will be same as task passed (but a copy of it) and last task will have 1st schedule only\r\
-- The task ID however have additional _n where n is a serial number from 1 \r\
function Karm.TaskObject.incSchTasks(task)\r\
	local taskList = {}\r\
	taskList[1] = Karm.TaskObject.copy(task)\r\
	taskList[1].TaskID = taskList[1].TaskID..\"_1\"\r\
	while taskList[#taskList].Schedules do\r\
		-- Find the latest schedule in the task here\r\
		if string.upper(taskList[#taskList].Status) == \"DONE\" and taskList[#taskList].Schedules.Actual then\r\
			-- Actual Schedule is the latest so remove this one\r\
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])\r\
			-- Remove the actual schedule\r\
			taskList[#taskList].Schedules.Actual = nil\r\
			-- Change the task ID\r\
			taskList[#taskList].TaskID = task.TaskID..\"_\"..tostring(#taskList)\r\
		elseif taskList[#taskList].Schedules.Revs then\r\
			-- Actual is not the latest one but Revision is \r\
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])\r\
			-- Remove the latest Revision Schedule\r\
			taskList[#taskList].Schedules.Revs[taskList[#taskList].Schedules.Revs.count] = nil\r\
			taskList[#taskList].Schedules.Revs.count = taskList[#taskList].Schedules.Revs.count - 1\r\
			if taskList[#taskList].Schedules.Revs.count == 0 then\r\
				taskList[#taskList].Schedules.Revs = nil\r\
			end\r\
			-- Change the task ID\r\
			taskList[#taskList].TaskID = task.TaskID..\"_\"..tostring(#taskList)\r\
		elseif taskList[#taskList].Schedules.Commit then\r\
			-- Actual and Revisions don't exist but Commit does\r\
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])\r\
			-- Remove the Commit Schedule\r\
			taskList[#taskList].Schedules.Commit = nil\r\
			-- Change the task ID\r\
			taskList[#taskList].TaskID = task.TaskID..\"_\"..tostring(#taskList)\r\
		elseif taskList[#taskList].Schedules.Estimate then\r\
			-- The latest is Estimate\r\
			taskList[#taskList + 1] = Karm.TaskObject.copy(taskList[#taskList])\r\
			-- Remove the latest Estimate Schedule\r\
			taskList[#taskList].Schedules.Estimate[taskList[#taskList].Schedules.Estimate.count] = nil\r\
			taskList[#taskList].Schedules.Estimate.count = taskList[#taskList].Schedules.Estimate.count - 1\r\
			if taskList[#taskList].Schedules.Estimate.count == 0 then\r\
				taskList[#taskList].Schedules.Estimate = nil\r\
			end\r\
			-- Change the task ID\r\
			taskList[#taskList].TaskID = task.TaskID..\"_\"..tostring(#taskList)\r\
		elseif not taskList[#taskList].Schedules.Estimate and not taskList[#taskList].Schedules.Commit\r\
		  and not taskList[#taskList].Schedules.Revs then\r\
		  	-- Since there can be an Actual Schedule but task is not done so Schedules cannot be nil\r\
		  	break\r\
		end\r\
		if not taskList[#taskList].Schedules.Estimate and not taskList[#taskList].Schedules.Commit \r\
		  and not taskList[#taskList].Schedules.Revs and not taskList[#taskList].Schedules.Actual then\r\
			taskList[#taskList].Schedules = nil\r\
		end\r\
	end			-- while taskList[#taskList].Schedules do ends\r\
	taskList[#taskList] = nil\r\
	return taskList\r\
end		-- function Karm.TaskObject.incSchTasks(task) ends\r\
\r\
-- Function to return an Empty task that satisfies the minimum requirements\r\
function Karm.getEmptyTask(SporeFile)\r\
	local nTask = {}\r\
	nTask[0] = \"Task\"\r\
	nTask.SporeFile = SporeFile\r\
	nTask.Title = \"DUMMY\"\r\
	nTask.TaskID = \"DUMMY\"\r\
	nTask.Start = \"1900-01-01\"\r\
	nTask.Public = true\r\
	nTask.Who = {[0] = \"Who\", count = 1,[1] = \"DUMMY\"}\r\
	nTask.Status = \"Not Started\"\r\
	Karm.TaskObject.MakeTaskObject(nTask)\r\
	return nTask\r\
end\r\
\r\
-- Function to cycle the planning schedule type for a task\r\
-- This function depends on the task setting methodology chosen to be in the sequence of Estimate->Commit->Revs->Actual\r\
-- So conversions are:\r\
-- Nothing->Estimate\r\
-- Estimate->Commit\r\
-- Commit->Revs\r\
-- Revs->Actual\r\
-- Actual->Back to Estimate\r\
function Karm.TaskObject.togglePlanningType(task,type)\r\
	if not task.Planning then\r\
		task.Planning = {}\r\
	end\r\
	if type == \"NORMAL\" then\r\
		local dateList = Karm.TaskObject.getLatestScheduleDates(task)\r\
		if not dateList then\r\
			dateList = {}\r\
			dateList.index = 0\r\
			dateList.typeSchedule = \"Estimate\"\r\
		end\r\
				\r\
		if not task.Planning.Type then\r\
			if dateList.typeSchedule == \"Estimate\" then\r\
				task.Planning.Type = \"Estimate\"\r\
				task.Planning.index = dateList.index + 1\r\
			elseif dateList.typeSchedule == \"Commit\" then\r\
				task.Planning.Type = \"Revs\"\r\
				task.Planning.index = 1\r\
			elseif dateList.typeSchedule == \"Revs\" then\r\
				task.Planning.Type = \"Revs\"\r\
				task.Planning.index = dateList.index + 1\r\
			else\r\
				task.Planning.Type = \"Actual\"\r\
				task.Planning.index = 1		\r\
			end\r\
		elseif task.Planning.Type == \"Estimate\" then\r\
			task.Planning.Type = \"Commit\"\r\
			task.Planning.index = 1\r\
		elseif task.Planning.Type == \"Commit\" then\r\
			task.Planning.Type = \"Revs\"\r\
			if task.Schedules and task.Schedules.Revs then\r\
				task.Planning.index = #task.Schedules.Revs + 1\r\
			else\r\
				task.Planning.index = 1\r\
			end\r\
		elseif task.Planning.Type == \"Revs\" then\r\
			-- in \"NORMAL\" type the schedule does not go to \"Actual\"\r\
			task.Planning.Type = \"Estimate\"\r\
			if task.Schedules and task.Schedules.Estimate then\r\
				task.Planning.index = #task.Schedules.Estimate + 1\r\
			else\r\
				task.Planning.index = 1\r\
			end\r\
		end		-- if not task.Planning.Type then ends\r\
	else\r\
		task.Planning.Type = \"Actual\"\r\
		task.Planning.index = 1\r\
	end		-- if type == \"NORMAL\" then ends\r\
end\r\
\r\
\r\
-- Function to toggle a planning date in the given task. If the planning schedule table is not present it creates it with the schedule type Estimate\r\
-- returns 1 if added, 2 if removed, 3 if removed and no more planning schedule left\r\
function Karm.TaskObject.togglePlanningDate(task,xmlDate,type)\r\
	if not task.Planning then\r\
		Karm.TaskObject.togglePlanningType(task,type)\r\
		task.Planning.Period = {\r\
									[0]=\"Period\",\r\
									count=1,\r\
									[1]={\r\
											[0]=\"DP\",\r\
											Date = xmlDate\r\
										}\r\
								}\r\
		\r\
		return 1\r\
	end\r\
	if not task.Planning.Period then\r\
		task.Planning.Period = {\r\
									[0]=\"Period\",\r\
									count=1,\r\
									[1]={\r\
											[0]=\"DP\",\r\
											Date = xmlDate\r\
										}\r\
								}\r\
		\r\
		return 1\r\
	end\r\
	for i=1,task.Planning.Period.count do\r\
		if task.Planning.Period[i].Date == xmlDate then\r\
			-- Remove this date\r\
			for j=i+1,task.Planning.Period.count do\r\
				task.Planning.Period[j-1] = task.Planning.Period[j]\r\
			end\r\
			task.Planning.Period[task.Planning.Period.count] = nil\r\
			task.Planning.Period.count = task.Planning.Period.count - 1\r\
			if task.Planning.Period.count>0 then\r\
				return 2\r\
			else\r\
				task.Planning = nil\r\
				return 3\r\
			end\r\
		elseif task.Planning.Period[i].Date > xmlDate then\r\
			-- Insert Date here\r\
			task.Planning.Period.count = task.Planning.Period.count + 1\r\
			for j = task.Planning.Period.count,i+1,-1 do\r\
				task.Planning.Period[j] = task.Planning.Period[j-1]\r\
			end\r\
			task.Planning.Period[i] = {[0]=\"DP\",Date=xmlDate}\r\
			return 1\r\
		end\r\
	end\r\
	-- Date must be added in the end\r\
	task.Planning.Period.count = task.Planning.Period.count + 1\r\
	task.Planning.Period[task.Planning.Period.count] = {[0]=\"DP\",Date = xmlDate	}\r\
	return 1\r\
end\r\
\r\
function Karm.TaskObject.add2Spore(task,dataStruct)\r\
	if not task.SubTasks then\r\
		task.SubTasks = {parent = dataStruct, tasks = 0, [0]=\"SubTasks\"}\r\
	end\r\
	dataStruct.tasks = dataStruct.tasks + 1\r\
	dataStruct[dataStruct.tasks] = task \r\
	if dataStruct.tasks > 1 then\r\
		dataStruct[dataStruct.tasks - 1].Next = dataStruct[dataStruct.tasks]\r\
		dataStruct[dataStruct.tasks].Previous = dataStruct[dataStruct.tasks-1]\r\
	end\r\
end\r\
\r\
function Karm.TaskObject.getNewChildTaskID(parent)\r\
	local taskID\r\
	if not parent.SubTasks then\r\
		taskID = parent.TaskID..\"_1\"\r\
	else \r\
		local intVar1 = 0\r\
		for count = 1,#parent.SubTasks do\r\
	        local tempTaskID = parent.SubTasks[count].TaskID\r\
	        if tonumber(tempTaskID:sub(-(#tempTaskID - #parent.TaskID - 1),-1)) > intVar1 then\r\
	            intVar1 = tonumber(tempTaskID:sub(-(#tempTaskID - #parent.TaskID - 1),-1))\r\
	        end\r\
		end\r\
		intVar1 = intVar1 + 1\r\
		taskID = parent.TaskID..\"_\"..tostring(intVar1)\r\
	end\r\
	return taskID\r\
end\r\
\r\
-- Function to add a task according to the specified relation\r\
function Karm.TaskObject.add2Parent(task, parent, Spore)\r\
	if not (task and parent) then\r\
		error(\"nil parameter cannot be handled at add2Parent in DataHandler.lua.\",2)\r\
	end\r\
	if getmetatable(task) ~= Karm.TaskObject or getmetatable(parent) ~= Karm.TaskObject then\r\
		error(\"Need a valid task and parent task object to add the task to parent\", 2)\r\
	end\r\
	if not parent.SubTasks then\r\
		parent.SubTasks = {tasks = 0, [0]=\"SubTasks\"}\r\
		if not parent.Parent then\r\
			if not Spore then\r\
				error(\"nil parameter cannot be handled at add2Parent in DataHandler.lua.\",2)\r\
			end\r\
			-- This is a Spore root node\r\
			parent.SubTasks.parent = Spore\r\
		else\r\
			parent.SubTasks.parent = parent.Parent.SubTasks\r\
		end \r\
	end\r\
	parent.SubTasks.tasks = parent.SubTasks.tasks + 1\r\
	parent.SubTasks[parent.SubTasks.tasks] = task\r\
	if parent.SubTasks.tasks > 1 then\r\
		parent.SubTasks[parent.SubTasks.tasks - 1].Next = parent.SubTasks[parent.SubTasks.tasks]\r\
		parent.SubTasks[parent.SubTasks.tasks].Previous = parent.SubTasks[parent.SubTasks.tasks-1]\r\
	end\r\
end\r\
\r\
-- Function to get all work done dates for a task and color and type for each date\r\
-- This function is called by the taskTree UI element to display the Gantt chart\r\
-- if bubble is true it bubbles up the latest schedule dates of the entire task hierarchy to this task\r\
--\r\
-- The function returns a table in the following format\r\
-- typeSchedule - Type of schedule for this task\r\
-- index - index of schedule for this task\r\
-- Subtables starting from index 1 corresponding to each date\r\
	-- Each subtable has the following keys:\r\
	-- Date - XML format date \r\
	-- typeSchedule - Type of schedule the date comes from \"Estimate\", \"Commit\", \"Revision\", \"Actual\"\r\
	-- index - the index of the schedule\r\
	-- Bubbled - True/False - True if date is from a subtask \r\
	-- BackColor - Background Color (Red, Green, Blue) table for setting the background color in the Gantt Chart\r\
	-- ForeColor - Foreground Color (Red, Green, Blue) table for setting the test color in the Gantt Chart date\r\
	-- Text - Text to be written in the Gantt cell for the date\r\
function Karm.TaskObject.getWorkDates(task,bubble)\r\
	local updateDateTable = function(task,dateTable)\r\
		local dateList = Karm.TaskObject.getWorkDoneDates(task)\r\
		if dateList then\r\
			if not dateTable then\r\
				dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}\r\
			end\r\
			for i = 1,#dateList do\r\
				local found = false\r\
				local index = 0\r\
				for j = 1,#dateTable do\r\
					if dateTable[j].Date == dateList[i] then\r\
						found = true\r\
						break\r\
					end\r\
					if dateTable[j].Date > dateList[i] then\r\
						index = j\r\
						break\r\
					end\r\
				end\r\
				if not found then\r\
					-- Create a space at index\r\
					for j = #dateTable, index, -1 do\r\
						dateTable[j+1] = dateTable[j]\r\
					end\r\
					local newColor = {Red=Karm.GUI.ScheduleColor.Red - Karm.GUI.bubbleOffset.Red,Green=Karm.GUI.ScheduleColor.Green - Karm.GUI.bubbleOffset.Green,\r\
					Blue=Karm.GUI.ScheduleColor.Blue-Karm.GUI.bubbleOffset.Blue}\r\
					if newColor.Red < 0 then newColor.Red = 0 end\r\
					if newColor.Green < 0 then newColor.Green = 0 end\r\
					if newColor.Blue < 0 then newColor.Blue = 0 end\r\
					dateTable[index] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, \r\
					  Bubbled = true, BackColor = newColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = \"\"}\r\
				end\r\
			end		-- for i = 1,#dateList do ends\r\
		end		-- if dateList then ends\r\
		return dateTable\r\
	end\r\
	if bubble then\r\
		local dateTable = Karm.TaskObject.applyFuncHier(task,updateDateTable)\r\
		return dateTable\r\
	else \r\
		-- Just get the latest dates for this task\r\
		local dateList = Karm.TaskObject.getWorkDoneDates(task)\r\
		if dateList then\r\
			-- Convert the dateList to modified return table\r\
			local dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}\r\
			for i = 1,#dateList do\r\
				dateTable[i] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, \r\
				  Bubbled = nil, BackColor = Karm.GUI.ScheduleColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = \"\"}\r\
			end\r\
			return dateTable\r\
		else\r\
			return nil\r\
		end\r\
	end\r\
end\r\
\r\
-- Function to get all dates for a task and color and type for each date\r\
-- This function is called by the taskTree UI element to display the Gantt chart\r\
-- if bubble is true it bubbles up the latest schedule dates of the entire task hierarchy to this task\r\
-- if planning is true it returns the planning date list for this task\r\
--\r\
-- The function returns a table in the following format\r\
-- typeSchedule - Type of schedule for this task\r\
-- index - index of schedule for this task\r\
-- Subtables starting from index 1 corresponding to each date\r\
	-- Each subtable has the following keys:\r\
	-- Date - XML format date \r\
	-- typeSchedule - Type of schedule the date comes from \"Estimate\", \"Commit\", \"Revision\", \"Actual\"\r\
	-- index - the index of the schedule\r\
	-- Bubbled - True/False - True if date is from a subtask \r\
	-- BackColor - Background Color (Red, Green, Blue) table for setting the background color in the Gantt Chart\r\
	-- ForeColor - Foreground Color (Red, Green, Blue) table for setting the test color in the Gantt Chart date\r\
	-- Text - Text to be written in the Gantt cell for the date\r\
function Karm.TaskObject.getDates(task,bubble,planning)\r\
	local plan = planning\r\
	local updateDateTable = function(task,dateTable)\r\
		local dateList = Karm.TaskObject.getLatestScheduleDates(task,plan)\r\
		if dateList then\r\
			if not dateTable then\r\
				dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}\r\
			end\r\
			for i = 1,#dateList do\r\
				local found = false\r\
				local index = 0\r\
				for j = 1,#dateTable do\r\
					if dateTable[j].Date == dateList[i] then\r\
						found = true\r\
						break\r\
					end\r\
					if dateTable[j].Date > dateList[i] then\r\
						index = j - 1\r\
						break\r\
					end\r\
				end\r\
				if not found then\r\
					-- Create a space at index + 1\r\
					for j = #dateTable, index+1, -1 do\r\
						dateTable[j+1] = dateTable[j]\r\
					end\r\
					local newColor = {Red=Karm.GUI.ScheduleColor.Red - Karm.GUI.bubbleOffset.Red,Green=Karm.GUI.ScheduleColor.Green - Karm.GUI.bubbleOffset.Green,\r\
					Blue=Karm.GUI.ScheduleColor.Blue-Karm.GUI.bubbleOffset.Blue}\r\
					if newColor.Red < 0 then newColor.Red = 0 end\r\
					if newColor.Green < 0 then newColor.Green = 0 end\r\
					if newColor.Blue < 0 then newColor.Blue = 0 end\r\
					dateTable[index+1] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, \r\
					  Bubbled = true, BackColor = newColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = dateList.typeSchedule:sub(1,1)}\r\
				end\r\
			end		-- for i = 1,#dateList do ends\r\
		end		-- if dateList then ends\r\
		return dateTable\r\
	end\r\
	if bubble then\r\
		-- Main task schedule\r\
		local dateTable = updateDateTable(task)\r\
		if dateTable then\r\
			for i = 1,#dateTable do\r\
				dateTable[i].Bubbled = nil\r\
				dateTable[i].BackColor = Karm.GUI.ScheduleColor\r\
				dateTable[i].Text = \"\"\r\
			end\r\
		end\r\
		plan = nil\r\
		dateTable = Karm.TaskObject.applyFuncHier(task,updateDateTable,dateTable, true)\r\
		return dateTable\r\
	else \r\
		-- Just get the latest dates for this task\r\
		local dateList = Karm.TaskObject.getLatestScheduleDates(task,planning)\r\
		if dateList then\r\
			-- Convert the dateList to modified return table\r\
			local dateTable = {typeSchedule = dateList.typeSchedule, index = dateList.index}\r\
			for i = 1,#dateList do\r\
				dateTable[i] = {Date = dateList[i], typeSchedule = dateList.typeSchedule, index = dateList.index, \r\
				  Bubbled = nil, BackColor = Karm.GUI.ScheduleColor, ForeColor = {Red=0,Green=0,Blue=0}, Text = \"\"}\r\
			end\r\
			return dateTable\r\
		else\r\
			return nil\r\
		end\r\
	end\r\
end\r\
\r\
-- function to update the taskID in the whole hierarchy\r\
function Karm.TaskObject.updateTaskID(task,taskID)\r\
	if not(task and taskID) then\r\
		error(\"Need a task and taskID for Karm.TaskObject.updateTaskID in DataHandler.lua\",2)\r\
	end\r\
	local prevTaskID = task.TaskID\r\
	Karm.TaskObject.applyFuncHier(task,function(task,taskIDs)\r\
							task.TaskID = task.TaskID:gsub(\"^\"..taskIDs.prevTaskID,taskIDs.newTaskID)\r\
							return taskIDs\r\
						end, {prevTaskID = prevTaskID, newTaskID = taskID}\r\
	)\r\
end\r\
\r\
-- Old Version\r\
--function Karm.TaskObject.updateTaskID(task,taskID)\r\
--	if not(task and taskID) then\r\
--		error(\"Need a task and taskID for Karm.TaskObject.updateTaskID in DataHandler.lua\",2)\r\
--	end\r\
--	local prevTaskID = task.TaskID\r\
--	task.TaskID = taskID\r\
--	if task.SubTasks then\r\
--		local currNode = task.SubTasks\r\
--		local hierCount = {}\r\
--		-- Traverse the task hierarchy here\r\
--		hierCount[currNode] = 0\r\
--		while hierCount[currNode] < #currNode or currNode.parent do\r\
--			if not(hierCount[currNode] < #currNode) then\r\
--				if currNode == task.SubTasks then\r\
--					-- Do not go above the passed task\r\
--					break\r\
--				end \r\
--				currNode = currNode.parent\r\
--			else\r\
--				-- Increment the counter\r\
--				hierCount[currNode] = hierCount[currNode] + 1\r\
--				currNode[hierCount[currNode]].TaskID = currNode[hierCount[currNode]].TaskID:gsub(\"^\"..prevTaskID,task.TaskID)\r\
--				if currNode[hierCount[currNode]].SubTasks then\r\
--					-- This task has children so go deeper in the hierarchy\r\
--					currNode = currNode[hierCount[currNode]].SubTasks\r\
--					hierCount[currNode] = 0\r\
--				end\r\
--			end\r\
--		end		-- while hierCount[hier] < #hier or hier.parent do ends here\r\
--	end		-- if task.SubTasks then ends\r\
--end\r\
\r\
-- Function to move the task before/after\r\
function Karm.TaskObject.bubbleTask(task,relative,beforeAfter,parent)\r\
	if task.Parent ~= relative.Parent then\r\
		error(\"The task and relative should be on the same level in the Karm.TaskObject.bubbleTask call in DataHandler.lua\",2)\r\
	end\r\
	if not (task.Parent or parent) then\r\
		error(\"parent argument should be specified for tasks/relative that do not have a parent defined in Karm.TaskObject.bubbleTask call in DataHandler.lua\",2)\r\
	end	\r\
	if task==relative then\r\
		return\r\
	end\r\
	local pTable, swapID\r\
	if not task.Parent then\r\
		-- These are root nodes in a spore\r\
		pTable = parent\r\
		swapID = false	-- since IDs for spore root nodes should not be swapped since they are roots and unique\r\
	else\r\
		pTable = relative.Parent.SubTasks\r\
		swapID = true\r\
	end\r\
	if beforeAfter:upper() == \"AFTER\" then\r\
		-- Next Sibling\r\
		-- Find the relative and task number\r\
		local posRel, posTask\r\
		for i = 1,pTable.tasks do\r\
			if pTable[i] == relative then\r\
				posRel = i\r\
			end\r\
			if pTable[i] == task then\r\
				posTask = i\r\
			end\r\
		end\r\
		if posRel < posTask then\r\
			-- Start the bubble up \r\
			for i = posTask,posRel+2,-1 do\r\
				if swapID then\r\
					-- Swap TaskID\r\
					local tim1 = pTable[i].TaskID\r\
					local ti = pTable[i-1].TaskID\r\
					Karm.TaskObject.updateTaskID(pTable[i],ti) \r\
					Karm.TaskObject.updateTaskID(pTable[i-1],tim1)\r\
				end \r\
				-- Swap task position\r\
				pTable[i],pTable[i-1] = pTable[i-1],pTable[i]\r\
				-- Update the Previous and Next pointers\r\
				pTable[i].Previous = pTable[i-1]\r\
				pTable[i-1].Next = pTable[i]\r\
				if i > 2 then\r\
					pTable[i-2].Next = pTable[i-1]\r\
					pTable[i-1].Previous = pTable[i-2]\r\
				else\r\
					pTable[i-1].Previous = nil\r\
				end\r\
				if i < pTable.tasks then\r\
					pTable[i].Next = pTable[i+1]\r\
					pTable[i+1].Previous = pTable[i]\r\
				else\r\
					pTable[i].Next = nil\r\
				end\r\
			end\r\
		else\r\
			-- Start the bubble down \r\
			for i = posTask,posRel-1 do\r\
				if swapID then\r\
					-- Swap TaskID\r\
					local tip1 = pTable[i].TaskID\r\
					local ti = pTable[i+1].TaskID\r\
					Karm.TaskObject.updateTaskID(pTable[i],ti) \r\
					Karm.TaskObject.updateTaskID(pTable[i+1],tip1)\r\
				end \r\
				-- Swap task position\r\
				pTable[i],pTable[i+1] = pTable[i+1],pTable[i]\r\
				-- Update the Previous and Next pointers\r\
				pTable[i+1].Previous = pTable[i]\r\
				pTable[i].Next = pTable[i+1]\r\
				if i > 1 then\r\
					pTable[i-1].Next = pTable[i]\r\
					pTable[i].Previous = pTable[i-1]\r\
				else\r\
					pTable[i].Previous = nil\r\
				end\r\
				if i+1 < pTable.tasks then\r\
					pTable[i+1].Next = pTable[i+2]\r\
					pTable[i+2].Previous = pTable[i+1]\r\
				else\r\
					pTable[i+1].Next = nil\r\
				end\r\
			end\r\
		end\r\
	else\r\
		-- Previous sibling\r\
		-- Find the relative and task number\r\
		local posRel, posTask\r\
		for i = 1,pTable.tasks do\r\
			if pTable[i] == relative then\r\
				posRel = i\r\
			end\r\
			if pTable[i] == task then\r\
				posTask = i\r\
			end\r\
		end\r\
		if posRel < posTask then\r\
			-- Start the bubble up \r\
			for i = posTask,posRel+1,-1 do\r\
				if swapID then\r\
					-- Swap TaskID\r\
					local tim1 = pTable[i].TaskID\r\
					local ti = pTable[i-1].TaskID\r\
					Karm.TaskObject.updateTaskID(pTable[i],ti) \r\
					Karm.TaskObject.updateTaskID(pTable[i-1],tim1)\r\
				end \r\
				-- Swap task position\r\
				pTable[i],pTable[i-1] = pTable[i-1],pTable[i]\r\
				-- Update the Previous and Next pointers\r\
				pTable[i].Previous = pTable[i-1]\r\
				pTable[i-1].Next = pTable[i]\r\
				if i > 2 then\r\
					pTable[i-2].Next = pTable[i-1]\r\
					pTable[i-1].Previous = pTable[i-2]\r\
				else\r\
					pTable[i-1].Previous = nil\r\
				end\r\
				if i < pTable.tasks then\r\
					pTable[i].Next = pTable[i+1]\r\
					pTable[i+1].Previous = pTable[i]\r\
				else\r\
					pTable[i].Next = nil\r\
				end\r\
			end\r\
		else\r\
			-- Start the bubble down \r\
			for i = posTask,posRel-2 do\r\
				if swapID then\r\
					-- Swap TaskID\r\
					local tip1 = pTable[i].TaskID\r\
					local ti = pTable[i+1].TaskID\r\
					Karm.TaskObject.updateTaskID(pTable[i],ti) \r\
					Karm.TaskObject.updateTaskID(pTable[i+1],tip1)\r\
				end \r\
				-- Swap task position\r\
				pTable[i],pTable[i+1] = pTable[i+1],pTable[i]\r\
				-- Update the Previous and Next pointers\r\
				pTable[i+1].Previous = pTable[i]\r\
				pTable[i].Next = pTable[i+1]\r\
				if i > 1 then\r\
					pTable[i-1].Next = pTable[i]\r\
					pTable[i].Previous = pTable[i-1]\r\
				else\r\
					pTable[i].Previous = nil\r\
				end\r\
				if i+1 < pTable.tasks then\r\
					pTable[i+1].Next = pTable[i+2]\r\
					pTable[i+2].Previous = pTable[i+1]\r\
				else\r\
					pTable[i+1].Next = nil\r\
				end\r\
			end\r\
		end\r\
	end\r\
\r\
end\r\
\r\
--function DeleteTaskFromSpore(task, Spore)\r\
--	if task.Parent then\r\
--		error(\"DeleteTaskFromSpore: Cannot delete task that is not a root task in Spore.\",2)\r\
--	end\r\
--	local taskList\r\
--	taskList = Spore\r\
--	for i = 1,#taskList do\r\
--		if taskList[i] == task then\r\
--			for j = i, #taskList-1 do\r\
--				taskList[j] = taskList[j+1]\r\
--			end\r\
--			taskList[#taskList] = nil\r\
--			taskList.tasks = taskList.tasks - 1\r\
--			break\r\
--		end\r\
--	end\r\
--end\r\
\r\
function Karm.TaskObject.DeleteFromDB(task)\r\
	local taskList\r\
	if not task.Parent then\r\
		taskList = task.SubTasks.parent		\r\
	else\r\
		taskList = task.Parent.SubTasks\r\
	end\r\
	for i = 1,#taskList do\r\
		if taskList[i] == task then\r\
			for j = i, #taskList-1 do\r\
				taskList[j] = taskList[j+1]\r\
				if j>1 then\r\
					taskList[j].Previous = taskList[j-1]\r\
					taskList[j-1].Next = taskList[j]\r\
				end\r\
			end\r\
			taskList[#taskList] = nil\r\
			taskList.tasks = taskList.tasks - 1\r\
			break\r\
		end\r\
	end\r\
end\r\
\r\
function Karm.sporeTitle(path)\r\
	-- Find the name of the file\r\
	local strVar\r\
	local intVar1 = -1\r\
	for intVar = #path,1,-1 do\r\
		if string.sub(path, intVar, intVar) == \".\" then\r\
	    	intVar1 = intVar\r\
		end\r\
		if string.sub(path, intVar, intVar) == \"\\\\\" or string.sub(path, intVar, intVar) == \"/\" then\r\
	    	strVar = string.sub(path, intVar + 1, intVar1-1)\r\
	    	break\r\
		end\r\
	end\r\
	if not strVar then\r\
		strVar = path\r\
	end\r\
	return strVar\r\
end\r\
\r\
function Karm.TaskObject.IsSpore(task)\r\
	if task.TaskID:sub(1,#Karm.Globals.ROOTKEY) == Karm.Globals.ROOTKEY then\r\
		return true\r\
	else\r\
		return false\r\
	end\r\
end\r\
\r\
-- Function to convert XML data from a single spore to internal data structure\r\
-- Task structure\r\
-- Task.\r\
--	Planning.\r\
--	[0] = Task\r\
-- 	SporeFile\r\
--	Title\r\
--	Modified\r\
--	DBDATA.\r\
--	TaskID\r\
--	Start\r\
--	Fin\r\
--	Private\r\
--	Who.\r\
--	Access.\r\
--	Assignee.\r\
--	Status\r\
--	Parent. = Pointer to the Task to which this is a sub task (Nil for root tasks in a Spore)\r\
--  Next. = Pointer to the next task under the same Parent (Nil if this is the last task)\r\
--  Previous. = Pointer to the previous task under the same Parent (Nil if this is the first task)\r\
--	Priority\r\
--	Due\r\
--	Comments\r\
--	Cat\r\
--	SubCat\r\
--	Tags.\r\
--	Schedules.\r\
--		[0] = \"Schedules\"\r\
--		Estimate.\r\
--			[0] = \"Estimate\"\r\
--			count\r\
--			[i] = \r\
--		Commit.\r\
--			[0] = \"Commit\"\r\
--		Revs\r\
--		Actual\r\
--	SubTasks.\r\
--		[0] = \"SubTasks\"\r\
--		parent  = pointer to the array containing the list of tasks having the task whose SubTask Node this is (Points to Spore table for root tasks of a Spore)\r\
--		tasks = count of number of subtasks\r\
--		[i] = Task table like this one repeated for sub tasks\r\
\r\
function Karm.XML2Data(SporeXML, SporeFile)\r\
	-- tasks counts the number of tasks at the current level\r\
	-- index 0 contains the name of this level to make it compatible with LuaXml\r\
	local dataStruct = {Title = Karm.sporeTitle(SporeFile), SporeFile = SporeFile, tasks = 0, TaskID = Karm.Globals.ROOTKEY..SporeFile, [0] = \"Task_Spore\"}	-- to create the data structure\r\
	if SporeXML[0]~=\"Task_Spore\" then\r\
		return nil\r\
	end\r\
	local currNode = SporeXML		-- currNode contains the current XML node being processed\r\
	local hierInfo = {}\r\
	hierInfo[currNode] = {count = 1}		-- hierInfo contains associated information with the currNode i.e. its Parent and count of the node being processed\r\
	while(currNode[hierInfo[currNode].count] or hierInfo[currNode].parent) do\r\
		if not(currNode[hierInfo[currNode].count]) then\r\
			currNode = hierInfo[currNode].parent\r\
			dataStruct = dataStruct.parent\r\
		else\r\
			if currNode[hierInfo[currNode].count][0] == \"Task\" then\r\
				local task = currNode[hierInfo[currNode].count]\r\
				hierInfo[currNode].count = hierInfo[currNode].count + 1\r\
				local necessary = 0\r\
				dataStruct.tasks = dataStruct.tasks + 1\r\
				dataStruct[dataStruct.tasks] = {[0] = \"Task\"}\r\
				\r\
				dataStruct[dataStruct.tasks].SporeFile = SporeFile\r\
				-- Set the Previous and next pointers\r\
				if dataStruct.tasks > 1 then\r\
					dataStruct[dataStruct.tasks].Previous = dataStruct[dataStruct.tasks - 1]\r\
				end\r\
				dataStruct[dataStruct.tasks].Next = dataStruct[dataStruct.tasks + 1]\r\
				-- Each task has a Parent Attribute which points to a parent Task containing this task. For root tasks in the spore this is nil\r\
				dataStruct[dataStruct.tasks].Parent = hierInfo[currNode].parentTask\r\
				-- Extract all task information here\r\
				local count = 1\r\
				while(task[count]) do\r\
					if task[count][0] == \"Title\" then\r\
						dataStruct[dataStruct.tasks].Title = task[count][1]\r\
						necessary = necessary + 1\r\
					elseif task[count][0] == \"Modified\" then\r\
						if task[count][1] == \"YES\" then\r\
							dataStruct[dataStruct.tasks].Modified = true\r\
						else\r\
							dataStruct[dataStruct.tasks].Modified = false\r\
						end\r\
						necessary = necessary + 1\r\
					elseif task[count][0] == \"DB-Data\" then\r\
						dataStruct[dataStruct.tasks].DBDATA = {[0]=\"DB-Data\",DBID = task[count][1][1], Updated = task[count][2][1]}\r\
					elseif task[count][0] == \"TaskID\" then\r\
						dataStruct[dataStruct.tasks].TaskID = task[count][1]\r\
						necessary = necessary + 1\r\
					elseif task[count][0] == \"Start\" then\r\
						dataStruct[dataStruct.tasks].Start = task[count][1]\r\
						necessary = necessary + 1\r\
					elseif task[count][0] == \"Fin\" then\r\
						dataStruct[dataStruct.tasks].Fin = task[count][1]\r\
					elseif task[count][0] == \"Private\" then\r\
						if task[count][1] == \"Private\" then\r\
							dataStruct[dataStruct.tasks].Private = true\r\
						else\r\
							dataStruct[dataStruct.tasks].Private = false\r\
						end\r\
						necessary = necessary + 1\r\
					elseif task[count][0] == \"People\" then\r\
						for j = 1,#task[count] do\r\
							if task[count][j][0] == \"Who\" then\r\
								local WhoTable = {[0]=\"Who\", count = #task[count][j]}\r\
								-- Loop through all the items in the Who element\r\
								for i = 1,#task[count][j] do\r\
									WhoTable[i] = {ID = task[count][j][i][1][1], Status = task[count][j][i][2][1]}\r\
								end\r\
								necessary = necessary + 1\r\
								dataStruct[dataStruct.tasks].Who = WhoTable\r\
							elseif task[count][j][0] == \"Locked\" then\r\
								local locked = {[0]=\"Access\", count = #task[count][j]}\r\
								-- Loop through all the items in the Locked element Access List\r\
								for i = 1,#task[count][j] do\r\
									locked[i] = {ID = task[count][j][i][1][1], Status = task[count][j][i][2][1]}\r\
								end\r\
								dataStruct[dataStruct.tasks].Access = locked\r\
							elseif task[count][j][0] == \"Assignee\" then\r\
								local assignee = {[0]=\"Assignee\", count = #task[count][j]}\r\
								-- Loop through all the items in the Assignee element\r\
								for i = 1,#task[count][j] do\r\
									assignee[i] = {ID = task[count][j][i][1]}\r\
								end				\r\
								dataStruct[dataStruct.tasks].Assignee = assignee					\r\
							end		-- if task[count][j][0] == \"Who\" then ends here				\r\
						end		-- for j = 1,#task[count] do ends here				\r\
					elseif task[count][0] == \"Status\" then\r\
						dataStruct[dataStruct.tasks].Status = task[count][1]\r\
						necessary = necessary + 1\r\
					elseif task[count][0] == \"Priority\" then\r\
						dataStruct[dataStruct.tasks].Priority = task[count][1]\r\
					elseif task[count][0] == \"Due\" then\r\
						dataStruct[dataStruct.tasks].Due = task[count][1]\r\
					elseif task[count][0] == \"Comments\" then\r\
						dataStruct[dataStruct.tasks].Comments = task[count][1]\r\
					elseif task[count][0] == \"Category\" then\r\
						dataStruct[dataStruct.tasks].Cat = task[count][1]\r\
					elseif task[count][0] == \"Sub-Category\" then\r\
						dataStruct[dataStruct.tasks].SubCat = task[count][1]\r\
					elseif task[count][0] == \"Tags\" then\r\
						local tagTable = {[0]=\"Tags\", count = #task[count]}\r\
						-- Loop through all the items in the Tags element\r\
						for i = 1,#task[count] do\r\
							tagTable[i] = task[count][i][1]\r\
						end\r\
						dataStruct[dataStruct.tasks].Tags = tagTable\r\
					elseif task[count][0] == \"Schedules\" then\r\
						local schedule = {[0]=\"Schedules\"}\r\
						for i = 1,#task[count] do\r\
							if task[count][i][0] == \"Estimate\" then\r\
								local estimate = {[0]=\"Estimate\", count = #task[count][i]}\r\
								-- Loop through all the estimates\r\
								for j = 1,#task[count][i] do\r\
									estimate[j] = {[0]=\"Estimate\"}\r\
									-- Loop through the children of Estimates element\r\
									for n = 1,#task[count][i][j] do\r\
										if task[count][i][j][n][0] == \"Hours\" then\r\
											estimate[j].Hours = task[count][i][j][n][1]\r\
										elseif task[count][i][j][n][0] == \"Comment\" then\r\
											estimate[j].Comment = task[count][i][j][n][1]\r\
										elseif task[count][i][j][0] == \"Updated\" then\r\
											estimate[j].Updated = task[count][i][j][n][1]\r\
										elseif task[count][i][j][n][0] == \"Period\" then\r\
											local period = {[0] = \"Period\", count = #task[count][i][j][n]}\r\
											-- Loop through all the day plans\r\
											for k = 1,#task[count][i][j][n] do\r\
												period[k] = {[0] = \"DP\", Date = task[count][i][j][n][k][1][1]}\r\
												if task[count][i][j][n][k][2] then\r\
													if task[count][i][j][n][k][2] == \"Hours\" then\r\
														period[k].Hours = task[count][i][j][n][k][2][1]\r\
													else\r\
														-- Collect all the time plans\r\
														period[k].TP = {[0]=\"Time Plan\", count = #task[count][i][j][n][k]-1}\r\
														for m = 2,#task[count][i][j][n][k] do\r\
															-- Add this time plan to the kth day plan\r\
															period[k].TP[m-1] = {STA = task[count][i][j][n][k][m][1][1], STP = task[count][i][j][n][k][m][2][1]}\r\
														end\r\
													end\r\
												end		-- if task[count][i][n][k][2] then ends\r\
											end		-- for k = 1,#task[count][i][j] do ends\r\
											estimate[j].Period = period\r\
										end		-- if task[count][i][j][0] == \"Hours\" then ends\r\
									end		-- for n = 1,#task[count][i][j] do ends\r\
								end		-- for j = 1,#task[count][i] do ends\r\
								schedule.Estimate = estimate\r\
							elseif task[count][i][0] == \"Commit\" then\r\
								local commit = {[0]=\"Commit\"}\r\
								commit.Comment = task[count][i][1][1][1]\r\
								commit.Updated = task[count][i][1][2][1]\r\
								local period = {[0] = \"Period\", count = #task[count][i][1][3]}\r\
								-- Loop through all the day plans\r\
								for k = 1,#task[count][i][1][3] do\r\
									period[k] = {[0] = \"DP\", Date = task[count][i][1][3][k][1][1]}\r\
									if task[count][i][1][3][k][2] then\r\
										if task[count][i][1][3][k][2] == \"Hours\" then\r\
											period[k].Hours = task[count][i][1][3][k][2][1]\r\
										else\r\
											-- Collect all the time plans\r\
											period[k].TP = {[0]=\"Time Plan\", count = #task[count][i][1][3][k]-1}\r\
											for m = 2,#task[count][i][1][3][k] do\r\
												-- Add this time plan to the kth day plan\r\
												period[k].TP[m-1] = {STA = task[count][i][1][3][k][m][1][1], STP = task[count][i][1][3][k][m][2][1]}\r\
											end\r\
										end\r\
									end		-- if task[count][i][n][k][2] then ends\r\
								end		-- for k = 1,#task[count][i][j] do ends\r\
								commit.Period = period\r\
								schedule.Commit = {commit,[0]=\"Commit\", count = 1}\r\
							elseif task[count][i][0] == \"Revs\" then\r\
								local revs = {[0]=\"Revs\", count = #task[count][i]}\r\
								-- Loop through all the Revisions\r\
								for j = 1,#task[count][i] do\r\
									revs[j] = {[0]=\"Revs\"}\r\
									-- Loop through the children of Revision element\r\
									for n = 1,#task[count][i][j] do\r\
										if task[count][i][j][n][0] == \"Comment\" then\r\
											revs[j].Comment = task[count][i][j][n][1]\r\
										elseif task[count][i][j][0] == \"Updated\" then\r\
											revs[j].Updated = task[count][i][j][n][1]\r\
										elseif task[count][i][j][n][0] == \"Period\" then\r\
											local period = {[0] = \"Period\", count = #task[count][i][j][n]}\r\
											-- Loop through all the day plans\r\
											for k = 1,#task[count][i][j][n] do\r\
												period[k] = {[0] = \"DP\", Date = task[count][i][j][n][k][1][1]}\r\
												if task[count][i][j][n][k][2] then\r\
													if task[count][i][j][n][k][2] == \"Hours\" then\r\
														period[k].Hours = task[count][i][j][n][k][2][1]\r\
													else\r\
														-- Collect all the time plans\r\
														period[k].TP = {[0]=\"Time Plan\", count = #task[count][i][j][n][k]-1}\r\
														for m = 2,#task[count][i][j][n][k] do\r\
															-- Add this time plan to the kth day plan\r\
															period[k].TP[m-1] = {STA = task[count][i][j][n][k][m][1][1], STP = task[count][i][j][n][k][m][2][1]}\r\
														end\r\
													end\r\
												end		-- if task[count][i][n][k][2] then ends\r\
											end		-- for k = 1,#task[count][i][j] do ends\r\
											revs[j].Period = period\r\
										end		-- if task[count][i][j][0] == \"Hours\" then ends\r\
									end		-- for n = 1,#task[count][i][j] do ends\r\
								end		-- for j = 1,#task[count][i] do ends\r\
								schedule.Revs = revs\r\
							elseif task[count][i][0] == \"Actual\" then\r\
								local actual = {[0]= \"Actual\", count = 1}\r\
								local period = {[0] = \"Period\", count = #task[count][i]-1} \r\
								-- Loop through all the work done elements\r\
								for j = 2,period.count+1 do\r\
									period[j] = {[0]=\"WD\", Date = task[count][i][j][1][1]}\r\
									for k = 2,#task[count][i][j] do\r\
										if task[count][i][j][k][0] == \"Hours\" then\r\
											period[j].Hours = task[count][i][j][k][1]\r\
										elseif task[count][i][j][k][0] == \"Comment\" then\r\
											period[j].Comment = task[count][i][j][k][1]\r\
										end\r\
									end\r\
								end\r\
								actual[1] = {Period = period,[0]=\"Actual\", Updated = task[count][i][1][1]}\r\
								schedule.Actual = actual\r\
							end							\r\
						end\r\
						dataStruct[dataStruct.tasks].Schedules = schedule\r\
					elseif task[count][0] == \"SubTasks\" then\r\
						hierInfo[task[count]] = {count = 1, parent = currNode,parentTask = dataStruct[dataStruct.tasks]}\r\
						currNode = task[count]\r\
						dataStruct[dataStruct.tasks].SubTasks = {parent = dataStruct, tasks = 0, [0]=\"SubTasks\"}\r\
						dataStruct = dataStruct[dataStruct.tasks].SubTasks\r\
					end\r\
					count = count + 1\r\
				end		-- while(task[count]) do ends\r\
				if necessary < 7 then\r\
					-- this is not valid task\r\
					dataStruct[dataStruct.tasks] = nil\r\
					dataStruct.tasks = dataStruct.tasks - 1\r\
				end\r\
			else\r\
				if currNode[hierInfo[currNode].parent] then\r\
					currNode = hierInfo[currNode].parent\r\
					dataStruct = dataStruct.parent\r\
				end		-- if currNode[hierInfo[level].parent ends here\r\
			end		-- if currNode[hierInfo[level].count][0] == \"Task\"  ends here\r\
		end		-- if not(currNode[hierInfo[currNode].count]) then ends\r\
	end		-- while(currNode[hierInfo[level].count]) ends here\r\
	while dataStruct.parent do\r\
		dataStruct = dataStruct.parent\r\
	end\r\
	\r\
	-- Convert all tasks to proper task Objects\r\
	local list1 = Karm.FilterObject.applyFilterHier(nil,Spore)\r\
	if #list1 > 0 then\r\
		for i = 1,#list1 do\r\
			Karm.TaskObject.MakeTaskObject(list1[i])\r\
		end\r\
	end        	\r\
	\r\
	-- Create a SubTasks node for each root node to get link to spore data table\r\
	for i = 1,#dataStruct do\r\
		if not dataStruct[i].SubTasks then\r\
			dataStruct[i].SubTasks = {parent = dataStruct, tasks = 0, [0]=\"SubTasks\"}\r\
		end\r\
	end\r\
	return dataStruct\r\
end		-- function Karm.XML2Data(SporeXML) ends here\r\
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
package.cpath = ";./?.so;"

require("wx")

-- DO ALL CONFIGURATION
Karm = {}
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


setmetatable(Karm.GUI,{__index = _G})

-- Global Declarations
Karm.Globals = {
	ROOTKEY = "T0",
	KARM_VERSION = "1.12.08.13",
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
		-- Update all the tasks in the planning mode in the UI to remove the planning schedule
		for i = 1,#oTree.taskList do
			if oTree.Nodes[oTree.taskList[i].TaskID].Row then
				dispGantt(taskTree,oTree.Nodes[oTree.taskList[i].TaskID].Row,false,oTree.Nodes[oTree.taskList[i].TaskID])
			end
		end 
		oTree.taskList = nil
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
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBTRACK, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_THUMBRELEASE, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEUP, f)
		oTree.treeGrid:Connect(wx.wxEVT_SCROLLWIN_LINEDOWN, f)
	
		f = onScrollGantt(taskTree)
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
				oTree.Selected = {oNode,Latest = 1}
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
				local env = getfenv()
				-- Write the up Values
				env.taskTreeINT = taskTreeINT
				env.tab = tab
				env.nodeMeta = nodeMeta
				env.dispTask = dispTask
				env.dispGantt = dispGantt
				--print(taskTreeINT)
				for i = 1,#oTree.actionQ do
					local f = loadstring(oTree.actionQ[i])
					setfenv(f,env)
					f()
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
		local parent = nodeMeta[node].Parent
		if not node then
			-- Already deleted
			return
		end
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
		oTree.Nodes[nodeMeta[node].Key] = nil
		nodeMeta[node] = nil
		oTree.nodeCount = oTree.nodeCount - 1
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

	local function onScrollTreeFunc(obj)
		return function(event)
			local oTree = taskTreeINT[obj]
			oTree.ganttGrid:Scroll(oTree.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.treeGrid:GetScrollPos(wx.wxVERTICAL))
			event:Skip()
		end
	end
	
--		 function onScTree(event)
--		 	oTree = event:GetEventObject()
--			--oTree = taskTreeINT[obj]
--			oTree.ganttGrid:Scroll(oTree.ganttGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.treeGrid:GetScrollPos(wx.wxVERTICAL))
--			event:Skip()
--		end
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
	
	local function onScrollGanttFunc(obj)
		return function(event)
			event:Skip()
			local oTree = taskTreeINT[obj]
			oTree.treeGrid:Scroll(oTree.treeGrid:GetScrollPos(wx.wxHORIZONTAL), oTree.ganttGrid:GetScrollPos(wx.wxVERTICAL))

			local currDate = oTree.startDate
			local finDate = oTree.finDate
			local count = 0
--			local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count))
--			y1 = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count+1),wx.wxGridCellCoords(0,count+1))
--   			Karm.GUI.frame:SetStatusText(tostring(y:GetTopLeft():GetX())..","..tostring(y:GetTopLeft():GetY())..","..
--   			  tostring(y1:GetTopLeft():GetX())..","..tostring(y1:GetTopLeft():GetY()), 1)
   			
    		local x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
    		--local y = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
    		local x = oTree.ganttGrid:IsVisible(0,count)
			--while x==0 and not currDate:IsLaterThan(finDate) do
			while not x and not currDate:IsLaterThan(finDate) do
				count = count + 1
				currDate = currDate:Add(wx.wxDateSpan(0,0,0,1))
				x = oTree.ganttGrid:IsVisible(0,count)
				--x = oTree.ganttGrid:BlockToDeviceRect(wx.wxGridCellCoords(0,count),wx.wxGridCellCoords(0,count)):GetTopLeft():GetX()
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
	onScrollGantt = onScrollGanttFunc
	onScrollTree = onScrollTreeFunc
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

function Karm.createNewSpore(title)
	local SporeName
	if title then
		SporeName = title
	else
		SporeName = wx.wxGetTextFromUser("Enter the New Spore File name under which to move the task (Blank to cancel):", "New Spore", "")
	end
	if SporeName == "" then
		return
	end
	Karm.SporeData[SporeName] = Karm.XML2Data({[0]="Task_Spore"}, SporeName)
	Karm.SporeData[SporeName].Modified = "YES"
	Karm.GUI.taskTree:AddNode{Relative=Karm.Globals.ROOTKEY, Relation="Child", Key=Karm.Globals.ROOTKEY..SporeName, Text=SporeName, Task = Karm.SporeData[SporeName]}
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
				task.SubTasks.parent = Karm.SporeData[task.SporeFile]
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
				task.SubTasks.parent = taskList[1].Task.SubTasks
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
				local SporeName
				if title then
					SporeName = title
				else
					SporeName = wx.wxGetTextFromUser("Enter the Spore File name (Blank to cancel):", "New Spore", "")
				end
				if SporeName == "" then
					return
				end
				Karm.SporeData[SporeName] = Karm.XML2Data({[0]="Task_Spore"}, SporeName)
				Karm.SporeData[SporeName].Modified = true
				Karm.SporeData[0] = Karm.SporeData[0] + 1
				if event:GetId() == Karm.GUI.ID_NEW_PREV_TASK then
	            	Karm.GUI.taskTree:AddNode{Relative=relativeID, Relation="PREV SIBLING", Key=Karm.Globals.ROOTKEY..SporeName, Text=SporeName, Task = Karm.SporeData[SporeName]}
	            else
	            	Karm.GUI.taskTree:AddNode{Relative=relativeID, Relation="NEXT SIBLING", Key=Karm.Globals.ROOTKEY..SporeName, Text=SporeName, Task = Karm.SporeData[SporeName]}
	            end
	            Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].ForeColor, Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName].BackColor = Karm.GUI.getNodeColor(Karm.GUI.taskTree.Nodes[Karm.Globals.ROOTKEY..SporeName])	
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
	local file,err,path
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
    textBox = wx.wxTextCtrl(splash, wx.wxID_ANY, "Version: "..Karm.Globals.KARM_VERSION, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_CENTRE + wx.wxBORDER_NONE + wx.wxTE_READONLY)
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
