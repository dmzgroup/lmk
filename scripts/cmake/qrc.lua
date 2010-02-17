require "lmkbuild"

local abs_path = lmkbuild.abs_path
local add_files = lmkbuild.add_files
local append = lmkbuild.append_local
local exec = lmkbuild.exec
local io = io
local file_newer = lmkbuild.file_newer
local function gset (name, value) 
   lmkbuild.set_global (name, value, true)
end
local ipairs = ipairs
local is_valid = lmkbuild.is_valid
local print = print
local resolve = lmkbuild.resolve
local rm = lmkbuild.rm
local set = lmkbuild.set_local
local split = lmkbuild.split

gset ("lmk.rccExec", {
   "$(DMZ_QT_HOME)/rcc -name $(rccName) $(rccSource) -o $(rccTarget)",
})

module (...)

local function resource_newer (item, target)
   local result = false
   local resources = {}
   local file = abs_path (item)
   if file then
      local fd = io.open (file, "r")
      if fd then
         local line = fd:read ("*line")
         while (line) do
            local resource = line:match ('%s*<file>%s*([%w_%-%./\\]+)</file>')
            if resource then
               resources[#resources + 1] = resource
            end
            line = fd:read ("*line")
         end
         io.close (fd)
      end
   end
   if resources then
      result = file_newer (resources, target)
   end
   return result
end

function main (files)
   append ("localIncludes", "$(lmk.includePathFlag).")
   local rccList = {}
   local execList = {}
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local rccTarget = resolve ("$(localTmpDir)qrc_".. file .. ".cpp")
      rccList[#rccList + 1] = rccTarget
      local build = false
      if file_newer (item, rccTarget) then build = true
      elseif resource_newer (item, rccTarget) then build = true
      end
      if build then
         set ("rccName", file)
         set ("rccSource", item)
         set ("rccTarget", rccTarget)
         execList[#execList + 1] = resolve ("$(lmk.rccExec)")
      end
   end
   exec (execList)
   add_files (rccList, "cpp")
end

function test (files)
   main (files)
end

function clean (files)
   local rccList = {}
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local rccTarget = resolve ("$(localTmpDir)qrc_".. file .. ".cpp")
      rccList[#rccList + 1] = resolve ("qrc_" .. file .. ".cpp")
      if rccTarget and is_valid (rccTarget) then rm (rccTarget) end
   end
   add_files (rccList, "cpp")
end

function clobber (files)
   clean (files)
end
