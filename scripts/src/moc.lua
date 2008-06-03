require "lmkbuild"

local add_files = lmkbuild.add_files
local append = lmkbuild.append_local
local exec = lmkbuild.exec
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

gset ("lmk.mocExec", {
   "$(DMZ_QT_HOME)/moc $(mocSource) -i -f$(mocSource) -o$(mocTarget)",
})

module (...)

function main (files)
   append ("localIncludes", "$(lmk.includePathFlag).")
   local mocList = {}
   local execList = {}
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local mocTarget = resolve ("$(localTmpDir)moc_".. file .. ".cpp")
      mocList[#mocList + 1] = mocTarget
      set ("mocTarget", mocTarget)
      local build = false
      if file_newer (item, mocTarget) then build = true
      end
      if build then
         set ("mocSource", item)
         execList[#execList + 1] = resolve ("$(lmk.mocExec)")
      end
   end
   exec (execList)
   add_files (mocList, "cpp")
end

function test (files)
   main (files)
end

function clean (files)
   local mocList = {}
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local mocTarget = resolve ("$(localTmpDir)moc_".. file .. ".cpp")
      mocList[#mocList + 1] = resolve ("moc_" .. file .. ".cpp")
      if mocTarget and is_valid (mocTarget) then rm (mocTarget) end
   end
   add_files (mocList, "cpp")
end

function clobber (files)
   clean (files)
end
