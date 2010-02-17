require "lmkbuild"

local abs_path = lmkbuild.abs_path
local add_files = lmkbuild.add_files
local append = lmkbuild.append_local
local dofile = dofile
local exec = lmkbuild.exec
local function gset (name, value)
   lmkbuild.set_global (name, value, true)
end
local ipairs = ipairs
local io = io
local file_newer = lmkbuild.file_newer
local find_file = lmkbuild.find_file
local get_var = lmkbuild.get_var
local is_valid = lmkbuild.is_valid
local pairs = pairs
local print = print
local resolve = lmkbuild.resolve
local rm = lmkbuild.rm
local set = lmkbuild.set_local
local split = lmkbuild.split
local sys = lmkbuild.system ()
local table  = table
local tostring = tostring

if sys == "win32" then
   gset ("lmk.includePathFlag", "") -- was /I
   gset ("lmk.defineFlag", "/D")
   gset ("lmk.libPathFlag", "/LIBPATH:")
   gset ("lmk.libSuffix", ".lib")
   gset ("lmk.shared.prefix", "")
   gset ("lmk.shared.ext", ".dll")
   gset ("lmk.plugin.ext", ".dll")
   gset ("lmk.exe.ext", ".exe")
else -- unix
   gset ("lmk.includePathFlag", "") -- was -I
   gset ("lmk.defineFlag", "-D")
   gset ("lmk.libPathFlag", "-L")
   gset ("lmk.libPrefix", "-l")
   gset ("lmk.shared.prefix", "lib")
   gset ("lmk.shared.ext", ".so")
   gset ("lmk.plugin.ext", ".plugin")
end


module (...)

function create_file_lists (files)
   local libs = get_var ("libs")
   if libs then
      for index, item in pairs (libs) do
         append (
            "localIncludes",
            "$(lmk.includePathFlag)$(lmk.includeDir)" .. item.. "/")
      end
   end
   local preqs = get_var ("preqs")
   if preqs then
      for index, item in pairs (preqs) do
         append (
            "localIncludes",
            "$(lmk.includePathFlag)$(lmk.includeDir)" .. item.. "/")
      end
   end
   local export = {}
   for _, src in ipairs (files) do
      export[#export + 1] = abs_path (src)
   end
   append ("cmake_src", export)
   local localInc = resolve "$(localIncludes)"
   local globalInc = resolve "$(lmk.globalIncludes)"
end

function clean_obj (files)
end
