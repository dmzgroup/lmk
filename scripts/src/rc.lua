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

gset ("lmk.rcExec", {
   "rc /fo$(rcTarget) $(rcSource)",
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
            local resource = line:match ('"([%w_%-%./\\]+)"')
            if resource then
print (resource)
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
   local rcList = {}
   local execList = {}
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local rcTarget = resolve ("$(localTmpDir)".. file .. ".res")
      rcList[#rcList + 1] = resolve (file .. ".res")
      local build = false
      if file_newer (item, rcTarget) then build = true
      elseif resource_newer (item, rcTarget) then build = true
      end
      if build then
         set ("rcSource", item)
         set ("rcTarget", rcTarget)
         execList[#execList + 1] = resolve ("$(lmk.rcExec)")
      end
   end
   exec (execList)
   add_files (rcList, "obj")
end

function test (files)
   main (files)
end

function clean (files)
   local rcList = {}
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local rcTarget = resolve ("$(localTmpDir)".. file .. ".res")
      rcList[#rcList + 1] = resolve (file .. ".res")
      if rcTarget and is_valid (rcTarget) then rm (rcTarget) end
   end
   add_files (rcList, "obj")
end

function clobber (files)
   clean (files)
end
