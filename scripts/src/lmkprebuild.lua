require "lmkbuild"

local append = lmkbuild.append_global
local mkdir = lmkbuild.mkdir
local rmdir = lmkbuild.rm
local resolve = lmkbuild.resolve
local set = lmkbuild.set_global
local system = lmkbuild.system
local print = print

module (...)

local function env_var_setup ()
   if resolve ("$(lmk.buildMode)") == "" then
      set ("lmk.buildMode", "debug")
   end
   set ("lmk.tmpDir", "$(lmk.projectRoot)tmp/" .. system () .. "-$(lmk.buildMode)/")
   set ("lmk.binDir", "$(lmk.projectRoot)bin/" .. system () .. "-$(lmk.buildMode)/")
   set ("lmk.libDir", "$(lmk.projectRoot)lib/" .. system () .. "-$(lmk.buildMode)/")
   set ("lmk.includeDir", "$(lmk.projectRoot)include/")
   append ("lmk.libPaths", "$(lmk.libPathFlag)$(lmk.binDir)")
   append ("lmk.libPaths", "$(lmk.libPathFlag)$(lmk.libDir)")
end

function main ()
   env_var_setup ()
   mkdir ("$(lmk.tmpDir)")
   mkdir ("$(lmk.binDir)")
   mkdir ("$(lmk.libDir)")
   mkdir ("$(lmk.includeDir)")
end

function test (files)
   main (files)
end

function clean ()
   env_var_setup ()
end

function clobber ()
   env_var_setup ()
end

function distclean () 
   rmdir ("$(lmk.projectRoot)tmp/")
   rmdir ("$(lmk.projectRoot)bin/")
   rmdir ("$(lmk.projectRoot)lib/")
   rmdir ("$(lmk.projectRoot)include/")
end
