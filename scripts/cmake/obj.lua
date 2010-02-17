require "lmkbuild"

local append = lmkbuild.append_local
local exec = lmkbuild.exec
local file_newer = lmkbuild.file_newer
local function gset (name, value)
   lmkbuild.set_global (name, value, true)
end
local lset = lmk.set_local
local get_var = lmkbuild.get_var
local ipairs = ipairs
local is_valid = lmkbuild.is_valid
local print = print
local resolve = lmkbuild.resolve
local rm = lmkbuild.rm
local set = lmkbuild.set_local
local sys = lmkbuild.system ()
local table = table

if sys == "win32" then
   gset ("lmk.libPathFlag", "/LIBPATH:")
   gset ("lmk.libSuffix", ".lib")
   gset ("lmk.shared.prefix", "")
   gset ("lmk.shared.ext", ".dll")
   gset ("lmk.plugin.ext", ".dll")
   gset ("lmk.exe.ext", ".exe")
else -- unix
   gset ("lmk.libPathFlag", "-L")
   gset ("lmk.libPrefix", "-l")
   gset ("lmk.shared.prefix", "lib")
   gset ("lmk.shared.ext", ".so")
   gset ("lmk.plugin.ext", ".plugin")
end

module (...)

function main (files)
   local binName =
      resolve ("$(lmk.$(type).prefix)$(name)$(lmk.$(type).ext)")
   set ("localBinName", binName)
   local binTarget =
      resolve ("$(lmk.binDir)" .. binName)
   set ("localBinTarget", binTarget)
end

function test (files)
   main (files)
end

function clobber (files)
   -- will need to remove windows specific files here
end
