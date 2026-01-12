version = 20260112.1200
--[[
	Last edited: see version YYYYMMDD.HHMM
	This will add all GUI toolkit (tk3) files and libraries
	Also a range of useful utilities
	If files exist it will compare the version and only update if newer
]]

local tmpDir = "tmp"	-- set temp folder name to 'tmp'
local files = {}		-- table of files
local fileSizes = {}	-- table of current file sizes

function clear()
	term.clear()
	term.setCursorPos(1, 1)
end

function log(text)
	-- Save comments to log file and print to screen
	print(text)
	local h = fs.open("update.log", "a")
	h.writeLine(text)
	h.close()
end

function checkLabel()
	-- check if computer has been labelled, ask user for a name if not
	if os.getComputerLabel() == nil then
		local noname = true
		while noname do
			clear()
			log("Give this turtle a name (no spaces)_")
			name = read()
			if name == '' then
				print("Just pressing Enter does not work")
			elseif string.find(name, ' ') ~= nil then
				print("NO SPACES!")
			else
				noname = false
			end
			if noname then
				sleep(2)
			end
		end
		
		os.setComputerLabel(name)
		log("Computer label set to "..os.getComputerLabel())
	end
end

function createTempDir()
	if fs.exists(tmpDir) then
		log("./"..tmpDir.." already exists")
	else
		log("./"..tmpDir.." created")
		fs.makeDir(tmpDir)
	end
end

function checkFile(url, fileName, tmpDir)
	if not fs.exists(fileName) then
		log("Missing fileName "..fileName..", trying Github")
	end
	local fileURL = url..fileName
	-- eg "https://raw.githubusercontent.com/Inksaver/Computercraft-GUI/main/lib/ui/Multibutton.lua"
	local response, message = http.get(fileURL)
	if response == nil then
		log("failed to get "..fileName.." from Github")
	else
		local data = response.readAll()
		response.close()
		local tempFile = getTempFileName(fileName)
		local h = fs.open(tempFile, "w")
		if h ~= nil then
			-- Save new fileName
			h.write(data)
			h.close()
			log(fileName.." saved from Github to ".. tempFile)
			return true
		end
	end
	return false
end

function getTempFileName(fileName)
	local tempFile = fs.getName(fileName)		-- extract file name only from path
	return fs.combine(tmpDir, tempFile)			-- create new file eg tmp/Class.lua from lib/Class.lua
end

function moveFile(fileName, tmpDir) 			-- move tmp copy to correct position
	fs.delete(fileName)
	sleep(1)
	local tempFile = getTempFileName(fileName)
	fs.move(tempFile, fileName) 				--move to correct position
	log("Moved: "..tempFile.." from "..tmpDir.." to ".. fileName)
end

function getVersion(line, fileName)
	-- version = 20201223.1104
	local version = 0
	if line == nil then
		log("Error reading "..fileName)
	else
		line = line:gsub(" ", "") -- remove spaces
		local start = line:find("=")
		
		if start ~= nil then -- found
			version = tonumber(line:sub(start + 1))
		end
	end
	
	return version
end

function isNewer(fileName, tmpDir)
	-- open files in tmp and original to read file version 
	local old = nil										-- declare old file handle
	local new = nil										-- declare new file handle
	local move = true									-- set move flag to true
	local oldOpen, newOpen = false, false

	if fs.exists(fileName) then	-- eg lib/Class.lua
		old = fs.open(fileName, "r")
		move = false
		oldOpen = true
	end
	
	if not move then 											-- previous version of file exists
		local tempFile = getTempFileName(fileName)
		if fs.exists(tempFile) then								-- should exist in tmp folder
			new = fs.open(tempFile, "r")
			newOpen = true
			local oldVer = getVersion(old.readLine(), fileName)	-- pass line 1 eg version = 20250915.1800
			log("Existing "..fileName.." version: "..oldVer)
			
			local newVer = getVersion(new.readLine(), fileName)
			log("Downloaded "..fileName.." version: "..newVer)
			if oldVer > 0 and newVer > 0 then					-- both have version numbers
				if newVer > oldVer then
					move = true
				end
			elseif oldVer == 0 and newVer > 0 then				-- new file has a number
				move = true
			end
		end
	end
	
	if newOpen then
		new.close()
	end
	if oldOpen then
		old.close()
	end
	return move
end

function process(url, fileName, tmpDir, fileSizes)
	local count = 0
	
	local freeSpace = fs.getFreeSpace("./")
	log("\nAvailable space: "..freeSpace)
	log("Checking: "..fileName)

	local fileSize = fileSizes[fileName]

	log(fileName.." size:"..fileSize)
	log("Available space after fetch: "..freeSpace - fileSize)
	if freeSpace - fileSize < 50000 then
		clear()
		local message = 
[[Insufficient disk space for update.
1. Save and close your game
2. delete any log files
3. Edit the fileName:
serverconfig/computercraft-server.toml
(in your game save folder)
4. Change line 2:
computer_space_limit = 1000000 to
computer_space_limit = 2000000 or more
5. Re-start the game
6. Run the updater again
]]
		log(message)
		return -1
	else
		if checkFile(url, fileName, tmpDir) then			-- download fileName to /tmp
			if isNewer(fileName, tmpDir) then
				moveFile(fileName, tmpDir) 					-- move tmp copy to correct location
				count = count  + 1
			else
				log(fileName.." is newer or unchanged")
			end
			sleep(1)
			local tempFile = getTempFileName(fileName)
			log("Removing "..tempFile)
			fs.delete(tempFile)
			sleep(2)
		end
	end
	
	return count
end

function addFileSize(fileSizes, fileName)
	if fs.exists(fileName) then
		fileSizes[fileName] = fs.getSize(fileName)
		log("File size "..fileName..": "..fileSizes[fileName])
	else
		fileSizes[fileName] = 0
		log("File size "..fileName.."\t: "..fileSizes[fileName].." (file not present)")
	end
	return fileSizes
end

function main()
	local doContinue = true							-- set continue flag						
	clear()
	checkLabel() 									-- make sure turtle label is set
	createTempDir() 								-- create /tmp/
	
	-- required for both turtle and advanced turtle
	if not fs.exists("lib") then
		fs.makeDir("lib")
	end
	if not fs.exists("lib/data") then
		fs.makeDir("lib/data")
	end
	if not fs.exists("lib/ui") then
		fs.makeDir("lib/ui")
	end
	if not fs.exists("scenes") then
		fs.makeDir("scenes")
	end
	
	local oldFileList =
	{	
		"b.lua", "d.lua", "f.lua", "flint.lua", "go.lua", "l.lua", "lavaRefuel.lua", "p.lua", "r.lua", "u.lua", "updater.lua", "x.lua"
	}
	
	local fileList = 
	{
		"tk3.lua",
		"lib/Class.lua", "lib/clsTurtle.lua", "lib/EntityMgr.lua", "lib/Events.lua", "lib/help.lua",  "lib/Log.lua", 
		"lib/menu.lua", "lib/Project.lua", "lib/Scene.lua", "lib/SceneMgr.lua", "lib/TurtleUtils.lua", "lib/Vector2.lua",
		"lib/data/taskInventory.lua", "lib/data/items.lua",
		"lib/ui/Button.lua", "lib/ui/Checkbox.lua", "lib/ui/ContentBar.lua", "lib/ui/Label.lua", 
		"lib/ui/ListBox.lua", "lib/ui/Multibutton.lua", "lib/ui/Multilabel.lua", "lib/ui/ScrollBar.lua", "lib/ui/Textbox.lua",
		"scenes/GetItems.lua", "scenes/Help.lua", "scenes/MainMenu.lua",
		"scenes/Quit.lua", "scenes/TaskOptions.lua",
	}
			
	local updated = 0
	local h = fs.open("update.log", "w")
	h.writeLine('Update Log:')
	h.close()
	
	log("Checking file sizes:\n")
	for _, file in ipairs(oldFileList) do
		fileSizes = addFileSize(fileSizes, file)
	end	
	for _, file in ipairs(fileList) do
		fileSizes = addFileSize(fileSizes, file)
	end	
	
	local freeSpace = fs.getFreeSpace("./")
	log("Free space before update: "..freeSpace.."\n")
	clear()
	
	local url = "https://raw.githubusercontent.com/Inksaver/Minecraft-Toolkit/main/"
	for _, file in ipairs(oldFileList) do 					
		updated = updated + process(url, file, tmpDir, fileSizes)		-- download files from Github to tmp/
	end
	
	url = "https://raw.githubusercontent.com/Inksaver/Computercraft-GUI/main/"
	for _, file in ipairs(fileList) do 					
		updated = updated + process(url, file, tmpDir, fileSizes)		-- download files from Github to tmp/
	end
	
	sleep(1)
	log("Attempting deletion of ./"..tmpDir)
	status, retval = pcall(fs.delete, tmpDir)
	if status then
		log("./"..tmpDir.." deleted")
	else
		log("Directory delete error message:\n "..tostring(retVal))
	end
	clear()
	log("\nOperation Complete ")
	log(updated.." files updated")

	print("See update.log for details")
end

main()
