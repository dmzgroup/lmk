require "lmkbuild"

local exec = lmkbuild.exec
local print = print
local resolve = lmkbuild.resolve

module (...)

function main (files)
end

function test (files)
   local testDefined = resolve ("$(test)")
   if testDefined ~= "" then exec ("$(lmk.$(lmk.buildMode).testExec)$(test)") end
end

function clean (files)
end

function clobber (files)
end
