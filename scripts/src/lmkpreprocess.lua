require "lmkbuild"

local mkdir = lmkbuild.mkdir
local set = lmkbuild.set_local
local print = print

module (...)

function main ()
   set ("localTmpDir", "$(lmk.tmpDir)$(name)/")
   mkdir ("$(localTmpDir)")
end

function test (files)
   main (files)
end

function clean ()
   set ("localTmpDir", "$(lmk.tmpDir)$(name)/")
end

function clobber ()
   clean ()
end
