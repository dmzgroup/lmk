require "lmkbuild"

local exec = lmkbuild.exec
local get_var = lmkbuild.get_var
local io = io
local ipairs = ipairs
local os = os
local print = print
local resolve = lmkbuild.resolve
local rm = lmkbuild.rm
local set_local = lmkbuild.set_local
local tostring = tostring
local get_build_number = lmkbuild.get_build_number

module (...)

function main (files)
   local vFileName = files[1]
   if vFileName then
      local name =  resolve ("$(appName)")
      if not name then name = resolve ("$(name)") end
      if name == "" then name = "UNKNOWN APPLICATION" end
      local major = resolve ("$(majorVersion)")
      if major == "" then major = "?" end
      local minor = resolve ("$(minorVersion)")
      if minor == ""  then minor = "?" end
      local bug = resolve ("$(bugVersion)")
      if bug == "" then bug = "?" end
      local rtype = resolve ("$(releaseType)")
      local image = resolve ("$(aboutImage)")
      local f = io.open (resolve ("$(localTmpDir)/" .. vFileName), "w")
      local build, p1, p2 = get_build_number ()
      if f then
         f:write ('<?xml version="1.0" encoding="UTF-8"?>\n')
         f:write ('<dmz>\n')
         f:write ('<version>\n')
         f:write ('   <name value="' .. name .. '"/>\n')
         f:write ('   <major value="' .. major.. '"/>\n')
         f:write ('   <minor value="' .. minor .. '"/>\n')
         f:write ('   <bug value="' .. bug .. '"/>\n')
         f:write ('   <build value="' .. build .. '"/>\n')
         if releaseType ~= "" then
            f:write ('   <release value="' .. rtype .. '"/>\n')
         end
         if image and image ~= "" then
            f:write ('   <image value="' .. image .. '"/>\n')
         end
         f:write ('</version>\n')
         f:write ('</dmz>\n')
         f:close ()
      end
      f = io.open (resolve ("$(localTmpDir)buildnumber.txt"), "w")
      if f then f:write (tostring (p1) .. tostring (p2)) f:close () end
   end   
end

function test (files)
end

function clean (files)
end

function clobber (files)
end
