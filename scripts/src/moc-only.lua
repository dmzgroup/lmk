require "lmkbuild"
require "moc"

local clean_moc = moc.clean
local main_moc = moc.main

module (...)

function main (files)
   main_moc (files, true);
end

function test (files)
   main_moc (files, true)
end

function clean (files)
   clean_moc (files, true)
end

function clobber (files)
   clean_moc (files, true)
end
