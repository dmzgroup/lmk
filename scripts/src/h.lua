require "lmkbuild"

local assert = assert
local append = lmkbuild.append_local
local cp = lmkbuild.cp
local file_newer = lmkbuild.file_newer
local ipairs = ipairs
local is_valid = lmkbuild.is_valid
local mkdir = lmkbuild.mkdir
local print = print
local resolve = lmkbuild.resolve
local rm = lmkbuild.rm
local split = lmkbuild.split

module (...)

function main (files)
   mkdir ("$(lmk.includeDir)$(name)")
   append ("localIncludes", "$(lmk.includePathFlag)$(lmk.includeDir)$(name)/")
   for index, item in ipairs (files) do
      item = resolve (item)
      p, f, e = split (item)
      file = "$(lmk.includeDir)$(name)/" .. f .. "." .. e
      if file_newer (item, file) then
         print ("Exporting: " .. item)
         assert (
            cp (item, file),
            "Failed copying file: " .. item .. " to " .. resolve (file))
      end
   end
end

function test (files)
   main (files)
end

function clean (files)
   for index, item in ipairs (files) do
      local p, f, e = split (item)
      local file = resolve ("$(lmk.includeDir)$(name)/" .. f .. "." .. e)
      if is_valid (file) then rm (file) end
   end
end

function clobber (files)
   clean (files)
end
