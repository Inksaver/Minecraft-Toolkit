version = 20230723.1200
--[[
	Last edited: see version YYYYMMDD.HHMM
	This is meant to be used as a library for any of your programs.
	Save it as menu.lua preferably in a subfolder called 'lib'
	To use it:
	local menu = require("lib.menu")
	
	local prompt = "Choose your option:"
	-- table of options, whatever text you like from 1 to 10 for turtles, 1 to 16 for computers
	local options = {"First choice", "Second choice", "Third choice", "Fourth choice", "Fifth choice",
					"Sixth choice","Seventh choice", "Eighth choice", "Ninth choice", "Tenth choice"}				
	local choice = menu.new(prompt, options) OR local choice = menu.menu(prompt, options)
	if choice == nil then
		print ("You chose to cancel the menu")
	else
		print("You chose option no "..choice..": "..options[choice])
	end
	
	menu.clear()
	local line, test, age = 1, "", 0, 0
	test, line = menu.getString("Type your name", true, 2, 10, line, colors.green, colors.black)
	line = line + 1
	age, line = menu.getInteger("Type your age", 5, 99, line, colors.black, colors.green)
	line = line + 1
]]
local menuPrompt = "Type number (q to quit) + Enter "
local width, height  = term.getSize()
local blank = (" "):rep(width)
local delay = 2
local sep 	= "~"
local lib = {}

function lib.clear()
	-- clear the terminal and reset cursor
	term.clear()
	term.setCursorPos(1, 1)
end

function lib.clearInputField(row)
	--[[ use setCursorPos to delete a line of text ]]
	local cols, rows = term.getSize()
	term.setCursorPos(1, row)
	print(blank) 					-- module variable
	if rows - row > 1 then
		term.setCursorPos(1, row + 1) 	-- next line in case overflow
		print(blank) 
	end
	term.setCursorPos(1, row) 		-- reset
end

function lib.formatPrompt(prompt)
	if prompt:endsWith(" ") then
		return prompt
	end
	
	return prompt.." "
end

function lib.padLeft(text, length, char)
	--[[Pads str to length len with char from left]]
	if char == nil then char = ' ' end
	local padding = ''
	for i = 1, length - #text do
		padding = padding..char
	end
	return padding..text
end

function lib.padRight(text, length, char)
	--[[
	Pads string to length len with chars from right
	test = lib.padRight("test", 10, "+") -> "test++++++"]]
	char = char or " "
	--if char == nil then char = ' ' end
	local padding = ''
	for i = 1, length - #text do
		padding = padding..char
	end
	return text..padding
end

function lib.resetColors()
	if term.isColor() then
		term.setTextColor(colors.white)
		term.setBackgroundColor(colors.black)
	end
end

function lib.trim(text)
	--[[ trim leading and trailing spaces ]]
	return (text:gsub("^%s*(.-)%s*$", "%1"))
end

function lib.print(text, fg, bg, width)
	local cols, rows = term.getSize()
	width = width or cols
	if width == 0 then width = cols end
	if width > cols then width = cols end
	local currentbg = colors.black
	local currentfg = colors.white
	if term.isColor() then
		fg = fg or term.getTextColor()
		bg = bg or term.getBackgroundColor()
		currentbg = term.getBackgroundColor()
		currentfg = term.getTextColor()
		term.setTextColor(fg)
		term.setBackgroundColor(bg)
	end
	print(lib.padRight(text, width, " "))
	if term.isColor() then
		term.setTextColor(currentfg)
		term.setBackgroundColor(currentbg)
	end
end

function lib.enterToContinue(prompt, fg, bg)
	prompt = prompt or "Enter to continue "
	term.setCursorPos(1, height)
	lib.write(prompt, fg , bg, nil, true)
	read()
end

function lib.write(text, fg, bg, width, isInput, cr)
	cr = cr or false
	local cols, rows = term.getSize()
	isInput = isInput or false
	width = width or cols
	if width == 0 then width = cols end
	if width > cols then width = cols end
	local currentbg = colors.black
	local currentfg = colors.white
	if term.isColor() then
		fg = fg or term.getTextColor()
		bg = bg or term.getBackgroundColor()
		currentbg = term.getBackgroundColor()
		currentfg = term.getTextColor()
		term.setTextColor(fg)
		term.setBackgroundColor(bg)
	end
	write(lib.padRight(text, width, " "))
	if term.isColor() then
		term.setTextColor(currentfg)
		term.setBackgroundColor(currentbg)
	end
	local _, row = term.getCursorPos()
	if isInput then
		term.setCursorPos(#text + 1, row)
	end
	if cr then
		term.setCursorPos(1, row)
	end
end

local function clear()
	lib.clear()
	return 1, 1
end

function string:count(c)
    --[[ count number of occurences of c ]]
	local _,n = self:gsub(c,"")
    return n
end

function string:endsWith(ending)
	--[[ get ending character of a string ]]
	return ending == "" or self:sub(-#ending) == ending
end

function string:split(sSeparator, nMax, bRegexp, noEmpty)
	--[[return a table split with sSeparator. noEmpty removes empty elements
		use: tblSplit = SplitTest:split('~',[nil], [nil], false) or tblSplit = string.split(SplitTest, '~')]]   
	assert(sSeparator ~= '','separator must not be empty string')
	assert(nMax == nil or nMax >= 1, 'nMax must be >= 1 and not nil')
	if noEmpty == nil then noEmpty = true end

	local aRecord = {}
	local newRecord = {}
	-- self refers to the 'string' being split
	if self:len() > 0 then
		local bPlain = not bRegexp
		nMax = nMax or -1

		local nField, nStart = 1, 1
		local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
		while nFirst and nMax ~= 0 do
			aRecord[nField] = self:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = self:find(sSeparator, nStart, bPlain)
			nMax = nMax-1
		end
		aRecord[nField] = self:sub(nStart)
		
		if noEmpty then --split on newline preserves empty values
			for i = 1, #aRecord do
				if aRecord[i] ~= "" then
					table.insert(newRecord, aRecord[i])
				end
			end
		else
			newRecord = aRecord
		end
	end
	
	return newRecord
end

local function colourText(row, text, reset)
	--[[
		This uses the default char ~ to separate colour strings                
		change the line:  sep = "~" as required                 				
		other possibles are ` (backtick) ¬ (NOT) or any character you will not use in text 
		example text = "~red~This is a line of red text"
	]]
	row = row or 1	
	term.setCursorPos(1, row)
	local newline = false
	if reset == nil then reset = true end
	row = row + text:count('\n') 		-- account for embedded newline characters
	if text:find(sep) ~= nil then 					-- text has colour tags in it eg  hello ~red~world
		local lineParts = text:split(sep)
		for i = 1, #lineParts do
			part = lineParts[i]
			if colors[part]~= nil then		-- is 'red' in the colors dictionary?
				-- change the TextColour
				if term.isColor() then
					term.setTextColor(colors[part])
				end
			else 									-- not a colour command so print it out without newline
				write(part)	-- NOT term.write as this does not use \n
			end
		end
		if reset and term.isColor() then
			term.setTextColor(colors.white)
		end
	else -- no colour tags in the text
		write(text)
		if not text:endsWith("\n") then
			newline = true
		end
	end
	if newline then
		write("\n")    -- Add newline to complete the print command
		row = row + 1
	end
	
	return row
end

local function errorMessage(row, errorType, userInput, minValue, maxValue)
	--local function drawError(prompt, options, width, height, errorNo, currentLine)
	--[[ Display error message to the user for <delay> seconds ]]
	minValue = minValue or 0
	maxValue = maxValue or 0
	local message = "Just Enter or spacebar doesn't work" -- default for "noinput"
	if errorType == "string" then
		message = "Text length -> "..minValue.." to "..maxValue.." characters"
	elseif errorType == "bool" then
		message = "Answer must start with y or n"
	elseif errorType == "nan" then
		message = "Enter a number "..userInput.." -> ?"
	elseif errorType == "notint" then
		message = "Enter a whole number only"
	elseif errorType == "range" then
		message = "Enter number from "..minValue.." to "..maxValue
	elseif errorType == "modifier" then
		message = "Number "..minValue.." to "..maxValue.." with 'h' or 'i' eg 3h"
	end

	lib.clearInputField(row)		-- clear row just used
	lib.write(message, colors.white, colors.red, width, false)
	sleep(delay)
	lib.clearInputField(row)
end

local function processInput(prompt, minValue, maxValue, dataType, row, fg, bg, default)
	--[[ validate input, raise error messages until input is valid ]]
	minValue = minValue or 0
	maxValue = maxValue or 1000000000
	dataType = dataType or "string"
	fg       = fg or colors.white
	bg       = bg or colors.black
	local col, line = term.getCursorPos()
	row = row or line
	local startRow = row
	local validInput = false
	local userInput
	if type(prompt) == "table" then
		assert(type(fg)  == "table", "Prompt is a table. Matching number of fg colours required")
	end
	while not validInput do
		for i = startRow, row do
			lib.clearInputField(row)
		end
		lib.clearInputField(row)
		if type(prompt) == "table" then
			row = startRow
			term.setCursorPos(1, row)
			for i = 1, #prompt do
				if i < #prompt then
					lib.print(prompt[i], fg[i], bg)
					row = row + 1
				else -- last line of multi-line prompt
					prompt[i] = lib.formatPrompt(prompt[i])
					lib.write(prompt[i], fg[i], bg, 0, true)
				end
			end
		else
			prompt = lib.formatPrompt(prompt)
			lib.write(prompt, fg, bg, width, true)
		end
		--lib.write(prompt..">", fg, bg, width, true)
		userInput = read():trim()
		local output = userInput
		if dataType == "string" then
			if userInput:len() == 0 and minValue > 0 then
				if default ~= nil then
					return default, row
				else
					errorMessage(row, "noinput", output, minValue, maxValue)
				end
			else
				if userInput:len() < minValue or userInput:len() > maxValue then
					errorMessage(row, "string", output, minValue, maxValue)
				else
					validInput = true
				end
			end
		else
			if userInput:len() == 0 then
				if default ~= nil then
					return default, row
				else
					errorMessage(row, "noinput", output, minValue, maxValue)
				end
			else
				if dataType == "bool" then		
					if userInput:sub(1, 1):lower() == "y" then
						userInput = true
						validInput = true
					elseif userInput:sub(1, 1):lower() == "n" then
						userInput = false
						validInput = true
					else
						errorMessage(row, "bool", output, minValue, maxValue)
					end
				else
					if dataType == "int" or dataType == "float" then
						userInput = tonumber(userInput)			
					end
					if userInput == nil then
						errorMessage(row, "nan", output, minValue, maxValue)
					else
						if userInput >= minValue and userInput <= maxValue then
							if math.floor(userInput / 1) ~= userInput and dataType == "int"  then
								errorMessage(row, "notint", output, minValue, maxValue)
							else
								validInput = true
							end
						else
							errorMessage(row, "range", output, minValue, maxValue)
						end
					end
				end
			end
		end
	end
	return userInput, row
end

local function drawMenu(prompt, options, width, height, pp, altMenuPrompt)
	local mPrompt = menuPrompt -- assign local variable to global value
	if altMenuPrompt ~= nil then
		mPrompt = lib.formatPrompt(altMenuPrompt) -- use different prompt
	else
		if not pp.allowModifier then
			mPrompt = "Type number + Enter "
		end
	end
	local numOptions = #options	
	if numOptions > height - 3 then
		numOptions = height - 3
	end
	lib.clear()
	lib.print(prompt, pp.prompt, colors.black, width)
	for i = 1, numOptions do
		local trimOption = string.sub(options[i], 1, width - 5)
		if i < 10 then
			lib.print("\t"..i..") ".."\t"..trimOption, pp.itemColours[i], colors.black, width)
		else
			lib.print("\t"..i..") "..trimOption, pp.itemColours[i], colors.black, width)
		end
	end
	lib.write(mPrompt, pp.menuPrompt, colors.black, width, true)
	lib.resetColors()

	return term.getCursorPos()
end

local function menu(prompt, options, pp, altMenuPrompt)
	--turtle   terminal size = 39 x 13 -- max menu options = 10, max option length = 34
	--computer terminal size = 51 x 19 -- max menu options = 16, max option length = 47
	--local width, height = term.getSize()
	local errorType = ""
	local choice = nil
	local modifier = ""
	local numOptions = #options
	if pp == nil then -- no prettyprint table supplied
		pp = {}
		pp.prompt = colors.green
		pp.itemColours = {}
		for i = 1, numOptions do
			table.insert(pp.itemColours, colors.white)
		end
		pp.menuPrompt = colors.yellow
		pp.allowModifier = false
	else
		assert(#options == #pp.itemColours, "Menu options (".. #options..") pp.itemColours (".. #pp.itemColours..") do not match")
	end
	prompt = lib.formatPrompt(prompt)
	while choice == nil and modifier == "" do
		local col, row = drawMenu(prompt, options, width, height, pp, altMenuPrompt)
		local isValid, isModifierValid, isNumberValid = false, false, false
		term.setCursorPos(col, row)
		if errorType ~= "" then
			errorMessage(row, errorType, choice, 1, #options)
			--lib.write(menuPrompt, pp.menuPrompt, colors.black, width, true)
			col, row = drawMenu(prompt, options, width, height, pp)
		end
		choice = read()
		if choice == "" then -- enter only
			errorType = "noinput"
			choice = nil
		else
			local test = tonumber(choice)
			if test == nil then	-- may have 3h 5i 2help etc
				if pp.allowModifier then
					if choice:lower():find("q") ~= nil then -- q(uit) entered
						return nil, "q" -- quit chosen
					elseif choice:lower():find("h") ~= nil then --h(elp)
						modifier = "h"			-- help chosen
						isModifierValid = true
						choice = tonumber(choice:sub(1, #choice - 1))
						if choice ~= nil then
							isNumberValid = true
						end
					elseif choice:lower():find("i") ~= nil then
						modifier = "i"			-- i(nventory) chosen
						isModifierValid = true
						choice = tonumber(choice:sub(1, #choice - 1))
						if choice ~= nil then
							isNumberValid = true
						end
					end
				else
					errorType = "nan"
					choice = nil
				end
			else -- user entered a number only
				choice = tonumber(choice)
				isNumberValid = true
			end
			if isNumberValid then -- number only or extracted number + modifier
				if math.floor(choice / 1) ~= choice then	
					errorType = "notint" -- integer only
					choice = nil
					modifier = ""
				elseif choice < 1 or choice > #options then
					errorType = "range"
					choice = nil
					modifier = ""
				end
			else
				errorType = "modifier" -- number missing
				choice = nil
				modifier = ""
			end
		end
	end
	lib.clear()
	return choice, modifier -- nil, "q" = quit | #, "h" = help needed for that choice | #, "" number chosen
end

local function tchelper(first, rest)
	return first:upper()..rest:lower()
end

local function toTitle(inputText) --converts any string to Title Case
	return inputText:gsub("(%a)([%w_']*)", tchelper)
end

local function getBool(prompt, row, fg, bg, default)
	--[[ Return a boolean. Based on y(es)/ n(o) response ]]
	return processInput(prompt, 1, 3, "bool", row, fg, bg, default)
end

local function getFloat(prompt, minVal, maxVal, row, fg, bg, default)
	return getNumber(prompt, minVal, maxVal, row, fg, bg, default)
end

local function getInteger(prompt, minValue, maxValue, row, fg, bg, default) 
	--[[ Return an integer. minValue and maxValue are given defaults if not passed ]]
	minValue = minValue or 0
	maxValue = maxValue or 65536

	return processInput(prompt, minValue, maxValue, "int", row, fg, bg, default) -- userInput, row
end

local function getNumber(prompt, minValue, maxValue, row, fg, bg, default) 
	--[[ Return a real number. minValue and maxValue are given defaults if not passed ]]
	minValue = minValue or -1000000000
	maxValue = maxValue or 	1000000000

	return processInput(prompt, minValue, maxValue, "float", row, fg, bg, default)
end

local function getString(prompt, withTitle, minValue, maxValue, row, fg, bg, default) 
--[[ Return a string. withTitle, minValue and maxValue are given defaults if not passed ]]
	withTitle = withTitle or false
	minInt = minInt or 1
	maxInt = maxInt or 20
	
	local userInput, row = processInput(prompt, minValue, maxValue, "string", row, fg, bg, default)
	if withTitle then
		userInput = toTitle(userInput)
	end
	
	return userInput, row
end

string.trim = lib.trim
string.padRight = lib.padRight		-- if using as library: string.PadRight = Xconsole.PadRight 
string.padLeft  = lib.padLeft		-- if using as library: string.PadLeft = Xconsole.PadLeft

return 
{
	clear = clear,				-- clear terminal, return 1,1
	menu = menu,				-- call menu function
	new = menu,					-- call menu function using new()
	getBool = getBool,			-- call getBool function
	getBoolean = getBool,		-- call getBool function using getBoolean()
	getNumber = getNumber,		-- call getNumber function
	getFloat = getNumber,		-- call getNumber function using getFloat()
	getInteger = getInteger,	-- call getInteger function
	getString = getString,		-- call getString function
	colourPrint = lib.print,	-- call lib.print function (print using specified colours)
	colorPrint = lib.print,		-- call lib.print function (print using specified colours) using colorPrint()
	colourWrite = lib.write,	-- call lib.write function (write using specified colours)
	colorWrite = lib.write,		-- call lib.write function (write using specified colours) using colorWrite()
	colourText = colourText,	-- call colourText function (print text with embedded colour strings)
	colorText = colourText,		-- call colourText function (print text with embedded colour strings) using colorText()
	enterToContinue = lib.enterToContinue, -- calls lib.enterToContinue to request user input
	padLeft = lib.padLeft,		-- call lib.padLeft
	padRight = lib.padRight		-- call lib.padRight
}