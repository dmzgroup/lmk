require "lmkbuild"

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

gset ("lmk.uicExec", {
   "$(DMZ_QT_HOME)/uic $(uicSource) -o $(uicTarget)",
})

module (...)

function main (files)
   append ("localIncludes", "$(lmk.includePathFlag)$(localTmpDir)")
   local uicList = {}
   local execList = {}
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local uicTarget = resolve ("$(localTmpDir)ui_".. file .. ".h")
      uicList[#uicList + 1] = uicTarget
      set ("uicTarget", uicTarget)
      local build = false
      if not is_valid (uicTarget) then build = true end
      if not build and file_newer (item, uicTarget) then build = true end
      if build then
         set ("uicSource", item)
         execList[#execList + 1] = resolve ("$(lmk.uicExec)")
      end
   end
   exec (execList)
end

function test (files)
   main (files)
end

function clean (files)
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local uicTarget = resolve ("$(localTmpDir)ui_".. file .. ".h")
      if uicTarget and is_valid (uicTarget) then rm (uicTarget) end
   end
end

function clobber (files)
   clean (files)
end
