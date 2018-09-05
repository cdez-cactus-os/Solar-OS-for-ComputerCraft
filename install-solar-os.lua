--[[ /gitget
GitHub downloading utility for CC.
Developed by apemanzilla. (thanks for that, by the way)
 
This requires ElvishJerricco's JSON parsing API.
Direct link: http://pastebin.com/raw.php?i=4nRg9CHU
]]--

-- Edit these variables to use preset mode.
-- Whether to download the files asynchronously (huge speed benefits, will also retry failed files)
-- If false will download the files one by one and use the old output (List each file name as it's downloaded) instead of the progress bar
local async = true

-- Whether to write to the terminal as files are downloaded
-- Note that unless checked for this will not affect pre-set start/done code below
local silent = false

local preset = {
	-- The GitHub account name
	user = "cdez-cactus-os",
	-- The GitHub repository name
	repo = "Solar-OS-for-ComputerCraft",
	
	-- The branch or commit tree to download (defaults to 'master')
	branch = "master",
	
	-- The local folder to save all the files to (defaults to '/')
	path = nil,
	
	-- Function to run before starting the download
	start = function()
		if not silent then print("Downloading files from GitHub...") end
	end,
	
	-- Function to run when the download completes
	done = function(path)
		if not silent then
			print("Deleting unneccesary files")
			fs.delete("Version 1.2.1")
			fs.delete("README.md")
			fs.delete("LICENCE")
			fs.delete("_config.yml")
			fs.delete("install-solar-os.lua")
			fs.delete("json")
			local list = fs.list(fs.combine(path, "Version 1.3.9/os"))
			for a = 1, #list do
				fs.move( fs.combine(fs.combine(path, "Version 1.3.9/os"), list[a]), fs.combine(path, list[a]) )
			end
			fs.delete("Version 1.3.9")
			print("Done!")
		end
	end
}

-- Leave the rest of the program alone.
local args = {...}

args[1] = preset.user or args[1]
args[2] = preset.repo or args[2]
args[3] = preset.branch or args[3] or "master"
args[4] = preset.path or args[4] or ""
 
if #args < 2 then
		print("Usage:\n"..((shell and shell.getRunningProgram()) or "gitget").." <user> <repo> [branch/tree] [path]") error()
end
 
local function save(data,file)
	local file = shell.resolve(file:gsub("%%20"," "))
	if not (fs.exists(string.sub(file,1,#file - #fs.getName(file))) and fs.isDir(string.sub(file,1,#file - #fs.getName(file)))) then
		if fs.exists(string.sub(file,1,#file - #fs.getName(file))) then fs.delete(string.sub(file,1,#file - #fs.getName(file))) end
		fs.makeDir(string.sub(file,1,#file - #fs.getName(file)))
	end
	local f = fs.open(file,"w")
	f.write(data)
	f.close()
end
 
local function download(url, file)
	save(http.get(url).readAll(),file)
end

if not json then
	download("http://pastebin.com/raw.php?i=4nRg9CHU","json")
	os.loadAPI("json")
end
 
preset.start()
local data = json.decode(http.get("https://api.github.com/repos/"..args[1].."/"..args[2].."/git/trees/"..args[3].."?recursive=1").readAll())
if data.message and data.message:find("API rate limit exceeded") then error("Out of API calls, try again later") end
if data.message and data.message == "Not found" then error("Invalid repository",2) else
	for k,v in pairs(data.tree) do
		-- Make directories
		if v.type == "tree" then
			fs.makeDir(fs.combine(args[4],v.path))
			if not hide_progress then
			end
		end
	end
	local drawProgress
	if async and not silent then
		local _, y = term.getCursorPos()
		local wide, _ = term.getSize()
		term.setCursorPos(1, y)
		term.write("[")
		term.setCursorPos(wide - 6, y)
		term.write("]")
		drawProgress = function(done, max)
			local value = done / max
			term.setCursorPos(2,y)
			term.write(("="):rep(math.floor(value * (wide - 8))))
			local percent = math.floor(value * 100) .. "%"
			term.setCursorPos(wide - percent:len(),y)
			term.write(percent)
		end
	end
	local filecount = 0
	local downloaded = 0
	local paths = {}
	local failed = {}
	for k,v in pairs(data.tree) do
		-- Send all HTTP requests (async)
		if v.type == "blob" then
			v.path = v.path:gsub("%s","%%20")
			local url = "https://raw.github.com/"..args[1].."/"..args[2].."/"..args[3].."/"..v.path,fs.combine(args[4],v.path)
			if async then
				http.request(url)
				paths[url] = fs.combine(args[4],v.path)
				filecount = filecount + 1
			else
				download(url, fs.combine(args[4], v.path))
				if not silent then print(fs.combine(args[4], v.path)) end
			end
		end
	end
	while downloaded < filecount do
		local e, a, b = os.pullEvent()
		if e == "http_success" then
			save(b.readAll(),paths[a])
			downloaded = downloaded + 1
			if not silent then drawProgress(downloaded,filecount) end
		elseif e == "http_failure" then
			-- Retry in 3 seconds
			failed[os.startTimer(3)] = a
		elseif e == "timer" and failed[a] then
			http.request(failed[a])
		end
	end
end
preset.done(args[4])
