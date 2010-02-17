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

module (...)

function main (files)
   append ("localIncludes", "$(lmk.includePathFlag)$(localTmpDir)")
end

function test (files)
   main (files)
end

function clean (files)
end

function clobber (files)
   clean (files)
end
