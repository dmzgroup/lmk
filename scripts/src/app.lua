require "lmkbuild"

local append_table = lmkbuild.append_table
local exec = lmkbuild.exec
local file_newer = lmkbuild.file_newer
local get_build_number = lmkbuild.get_build_number
local get_var = lmkbuild.get_var
local io = io
local ipairs = ipairs
local is_dir = lmkbuild.is_dir
local is_valid = lmkbuild.is_valid
local mkdir = lmkbuild.mkdir
local cp = lmkbuild.cp
local copy_file = lmkbuild.copy_file
local print = print
local resolve = lmkbuild.resolve
local rm = lmkbuild.rm
local set_local = lmkbuild.set_local
local split = lmkbuild.split_path_and_file
local system = lmkbuild.system ()
local tostring = tostring

module (...)

local data = {}

local function local_copy (src, target)
   local isNewer = false
   src = resolve (src)
   target = resolve (target)
   if is_valid (src) then
      if is_dir (target) then
         local path, file = split (src)
         target = target .. "/" .. file
      end
      if file_newer (src, target) then cp (src, target); isNewer = true end
   else target = nil
   end
   return target, isNewer
end

function set_app (file, target)
   data = {}
   data.app = file
   data.appTarget = target
end

function set_plist (file)
   data.plist = file
end

function add_icons (files)
   if data.icons then append_table (data.icons, files)
   else data.icons = files
   end
end

function add_config (files)
   if data.config then append_table (data.config, files)
   else data.config = files
   end
end

function add_data (files)
   if data.data then append_table (data.data, files)
   else data.data = files
   end
end

function add_scripts (files)
   if data.scripts then append_table (data.scripts, files)
   else data.scripts = files
   end
end

local function main_mac (files)
   local targetName = resolve ("$(lmk.binDir)" .. files[1])
   local contentsTarget = targetName .. "/Contents"
   local frameworksTarget = contentsTarget .. "/Frameworks"
   local appTarget = contentsTarget .. "/MacOS"
   local resourcesTarget = contentsTarget .. "/Resources"
   local configTarget = resourcesTarget .. "/config"
   local dataTarget = resourcesTarget .. "/assets"
   local scriptsTarget = resourcesTarget .. "/scripts"
   mkdir (frameworksTarget)
   mkdir (appTarget)
   mkdir (configTarget)
   mkdir (dataTarget)
   mkdir (scriptsTarget)

   if data.appTarget then appTarget = appTarget .. "/" .. data.appTarget end

   local preqs = get_var ("preqs")
   if preqs then
      local installPaths = get_var ("installPaths")
      for index, item in ipairs (preqs) do
         local src = "$(" .. item .. ".localBinTarget)"
         local target = nil
         local isNewer = false
         if item == data.app then
            target, isNewer = local_copy (src, appTarget)
            if target and isNewer then exec ("chmod u+x " .. target) end
         else target, isNewer = local_copy (src, frameworksTarget)
         end
         if target and isNewer and installPaths then
            for index, paths in ipairs (installPaths) do
               local arg = "install_name_tool -change " .. paths[1] .. " "
                  .. paths[2] .. " " .. target
               exec (arg)
            end
         end
      end
   end

   if data.config then
      for index, item in ipairs (data.config) do
         local_copy (item, configTarget)
      end
   end

   if data.plist then
      --local_copy (data.plist, contentsTarget)
      local buildVersion = get_build_number ()
      set_local ("buildVersion", buildVersion)
      local src = resolve (data.plist)
      if is_valid (src) then
         local path, file = split (src)
         local target = contentsTarget .. "/" .. file
         local fileOut = io.open (target, "w")
         if fileOut then
            for line in io.lines(src) do
               line = resolve (line)
               fileOut:write (line .. "\r\n")
            end
         end
      end
   end

   if data.icons then
      for index, item in ipairs (data.icons) do
         local_copy (item, resourcesTarget)
      end
   end

   if data.data then 
      for index, item in ipairs (data.data) do
         if not is_valid (item) then
            item = resolve ("$(lmk.projectRoot)" .. item)
         end
         if is_valid (item) then local_copy (item, dataTarget)
         else print ("ERROR: Invalid data item: " .. item)
         end
      end
   end

   if data.scripts then
      for index, item in ipairs (data.scripts) do
         local_copy (item, scriptsTarget)
      end
   end

   --last line!
   data = {}
end


local function main_win32 (files)
   local appTarget = resolve ("$(lmk.binDir)" .. files[1])
   local binTarget = appTarget .. "/bin"
   local configTarget = appTarget .. "/config"
   local dataTarget = appTarget .. "/assets"
   local scriptsTarget = appTarget .. "/scripts"
   mkdir (binTarget)
   mkdir (configTarget)
   mkdir (dataTarget)
   mkdir (scriptsTarget)

   local preqs = get_var ("preqs")
   if preqs then
      for index, item in ipairs (preqs) do
         local src = "$(" .. item .. ".localBinTarget)"
         local_copy (src, binTarget)
      end
   end

   if data.config then
      for index, item in ipairs (data.config) do
         local_copy (item, configTarget)
      end
   end

   if data.data then
      for index, item in ipairs (data.data) do
         if not is_valid (item) then
            item = resolve ("$(lmk.projectRoot)" .. item)
         end
         if is_valid (item) then local_copy (item, dataTarget)
         else print ("ERROR: Invalid data item: " .. item)
         end
      end
   end

   if data.scripts then
      for index, item in ipairs (data.scripts) do
         local_copy (item, scriptsTarget)
      end
   end

   --last line!
   data = {}
end


function main (files)
   if system == "macos" then main_mac (files)
   elseif system == "win32" then main_win32 (files)
   end
end

function test (files)
   --last line!
   data = {}
end

function clean (files)
   --last line!
   data = {}
end

function clobber (files)
   local targetName = resolve ("$(lmk.binDir)" .. files[1])
   rm (targetName)
   --last line!
   data = {}
end
