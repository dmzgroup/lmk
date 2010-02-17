require "lmkbuild"

local get_var = lmkbuild.get_var
local io = io
local pairs = pairs
local print = print
local resolve = lmkbuild.resolve

module (...)

function main ()
   local fileName = resolve ("$(lmk.cmakeDir)CMakeLists.txt")
   local file = io.open (fileName, "w")
   if file then
      file:write ("cmake_minimum_required(VERSION 2.8.0 FATAL_ERROR)\n")
      file:write ("project(dmz)\n")
      local list = get_var ("lmk.nameList")
      if list then
         for _, name in pairs (list) do
            file:write ("add_subdirectory(./targets/" .. name .. ")\n")
         end
      end
      file:close ()
      file = nil
   end
   print ("")
   print ("Build completed successfully")
end

function test (files)
   print ("")
   print ("Unit tests completed successfully")
end

function clean (files)
   print ("")
   print ("Clean completed successfully")
end

function clobber (files)
   print ("")
   print ("Clobber completed successfully")
end

function distclean (files)
   print ("")
   print ("Distclean completed successfully")
end

