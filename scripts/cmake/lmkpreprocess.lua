require "lmkbuild"

local mkdir = lmkbuild.mkdir
local set = lmkbuild.set_local
local print = print
local resolve = lmkbuild.resolve

module (...)

function main ()
   set ("localCMakeDir", "$(lmk.cmakeDir)targets/$(name)/")
   set ("localTmpDir", "$(lmk.tmpDir)$(name)/")
   mkdir ("$(localCMakeDir)")
   mkdir ("$(localTmpDir)")
end

function test (files)
   main (files)
end

function clean ()
   set ("localCMakeDir", "$(lmk.cmakeDir)$(name)/")
   set ("localTmpDir", "$(lmk.tmpDir)$(name)/")
end

function clobber ()
   clean ()
end
