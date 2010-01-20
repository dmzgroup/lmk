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
   gset ("lmk.cppExec", {
      "$(lmk.cpp.$(lmk.buildMode))",
      "$(lmk.cppFlags.$(lmk.buildMode))$(file)",
      "$(localIncludes)",
      "$(lmk.globalIncludes)",
      "$(localDefines)",
      "$(lmk.globalDefine)",
      "/c /Fo$(objectTarget)",
   })
   gset ("lmk.ccExec", {
      "$(lmk.cc.$(lmk.buildMode))",
      "$(lmk.ccFlags.$(lmk.buildMode))$(file)",
      "$(localIncludes)",
      "$(lmk.globalIncludes)",
      "$(localDefines)",
      "$(lmk.globalDefines)",
      "/c /Fo$(objectTarget)",
   })
   local cflagsOpt = "/nologo /EHsc /MD /Ox /GR /W3" -- /WX
   local cflagsDebug = "/nologo /EHsc /MDd /GR /W3 /Z7 /RTC1" -- /WX
   gset ("lmk.objExt", ".obj")
   gset ("lmk.includePathFlag", "/I")
   gset ("lmk.defineFlag", "/D")
   gset ("lmk.cpp.opt", "cl.exe")
   gset ("lmk.cpp.debug", "cl.exe")
   gset ("lmk.cpp.bc", "nmcl.exe")
   gset ("lmk.cppFlags.opt", cflagsOpt .. " /Tp")
   gset ("lmk.cppFlags.debug", cflagsDebug .. " /Tp")
   gset ("lmk.cppFlags.bc", cflagsDebug .. " /Tp")
   gset ("lmk.cc.opt", "cl.exe")
   gset ("lmk.cc.debug", "cl.exe")
   gset ("lmk.cc.bc", "nmcl.exe")
   gset ("lmk.ccFlags.opt", cflagsOpt .. " /Tc")
   gset ("lmk.ccFlags.debug", cflagsDebug .. " /Tc")
   gset ("lmk.ccFlags.bc", cflagsDebug .. " /Tc")
else -- unix
   gset ("lmk.cppExec", {
      "$(lmk.cpp)",
      "$(lmk.cppFlags.$(lmk.buildMode))",
      "$(localIncludes)",
      "$(lmk.globalIncludes)",
      "$(localDefines)",
      "$(lmk.globalDefines)",
      "$(file)",
      "-c -o $(objectTarget)",
   })
   gset ("lmk.ccExec", {
      "$(lmk.cc)",
      "$(lmk.ccFlags.$(lmk.buildMode))",
      "$(localIncludes)",
      "$(lmk.globalIncludes)",
      "$(localDefines)",
      "$(lmk.globalDefines)",
      "$(file)",
      "-c -o $(objectTarget)",
   })
   gset ("lmk.objExt", ".o")
   gset ("lmk.includePathFlag", "-I")
   gset ("lmk.defineFlag", "-D")
   if sys == "macos" then
      gset ("lmk.cpp", "g++")
      gset ("lmk.cppFlags.opt", "-O")
      gset ("lmk.cppFlags.debug", "-g -fPIC")
      gset ("lmk.cc", "gcc")
      gset ("lmk.ccFlags.opt", "-O")
      gset ("lmk.ccFlags.debug", "-g -fPIC")
   elseif sys == "iphone" then
      local iphoneFlags = " -arch armv6 -pipe -Wno-trigraphs " ..
         "-fpascal-strings -fasm-blocks -Wreturn-type -Wunused-variable " ..
         "-fmessage-length=0 -fvisibility=hidden -miphoneos-version-min=2.0 " ..
         "-gdwarf-2 -mthumb " ..
         "-isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/" ..
         "iPhoneOS2.0.sdk -DDMZ_IPHONE_BUILD"
      gset ("lmk.cpp", "/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/" ..
         "arm-apple-darwin9-g++-4.0.1" .. iphoneFlags)
      gset ("lmk.cppFlags.opt", "-O0")
      gset ("lmk.cppFlags.debug", "-g")
      gset ("lmk.cc", "/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/" ..
         "arm-apple-darwin9-gcc-4.0.1" .. iphoneFlags)
      gset ("lmk.ccFlags.opt", "-O0")
      gset ("lmk.ccFlags.debug", "-g")
   elseif sys == "linux" then
      gset ("lmk.cpp", "g++")
      gset ("lmk.cppFlags.opt", "-O")
      gset ("lmk.cppFlags.debug", "-g")
      gset ("lmk.cc", "gcc")
      gset ("lmk.ccFlags.opt", "-ansi -O")
      gset ("lmk.ccFlags.debug", "-ansi -g")
   end
end

module (...)

local cache = {}

local function get_depend_file_name (file, ext)
   return resolve ("$(localTmpDir)" .. file .. "." .. ext .. ".depend")
end

local function depend_list (file, list)
    if not list[file] then
       list[file] = true
       for key, v in pairs (cache[file]) do
          if not list[v] then depend_list (v, list) end
       end
    end
end

local function depend (item, dependFile, paths)
   local file = abs_path (item)
   if file then
      local d = cache[file]
      if not d then
         d = {}
         cache[file] = d
         local fd = io.open (file, "r")
         if fd then
            local line = fd:read ("*line")
            while (line) do
               local header = line:match ('^#%s*include%s*["<]?([%w_%./\\]+)')
               if header then
                  header = find_file (header, paths)
                  if header then header = depend (header, nil, paths) end
                  if header then d[#d + 1] = header end
               end
               line = fd:read ("*line")
            end
            io.close (fd)
         end
      end
      if dependFile then
         local list = {}
         depend_list (file, list)
         fd = io.open (dependFile, "w")
         if fd then
            fd:write ("return {\n")
            for key in pairs (list) do fd:write ('"' .. key .. '",\n') end
            fd:write ("}\n")
            io.close (fd)
         end
      end
   else
   end
   return file
end

local function header_newer (item, file, ext, paths)
   local result = false
   local dependFile = get_depend_file_name (file, ext)
   local dependCreated = false
   if file_newer (item, dependFile) then
      depend (item, dependFile, paths)
      dependCreated = true
   end
   local headers = dofile (dependFile)
   if headers then
       result = file_newer (headers, "$(objectTarget)")
   end
   if result and not dependCreated then depend (item, dependFile, paths) end
   return result
end

local function str_to_table (str, delimiter)
    local paths = nil
    if str then
       local done = false
       local pend = nil
       local cstart, cend = 1, nil
       while not done do
          cstart, cend = str:find (delimiter, cstart)
          if cend then
             if pend then
                if not paths then paths = {} end
                paths[#paths + 1] = str:sub (pend + 1, cstart - 1)
             end
             pend = cend
             cstart = cend + 1
          else done = true
          end
       end
       if pend then
          if not paths then paths = {} end
          paths[#paths + 1] = str:sub (pend + 1, -1)
       end
    end
    return paths
end

function create_file_lists (files, execVar)
   if sys == "iphone" then
      append ("localIncludes", "$(lmk.includePathFlag)$(lmk.includeDir)dmz/")
   else
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
   end
   local execList, objList = {}, {}
   local localInc = resolve "$(localIncludes)"
   local globalInc = resolve "$(lmk.globalIncludes)"
   local paths = nil
   if (globalInc ~= "") and (localInc ~= "") then
      paths = " " .. globalInc .. " " .. localInc
   else paths = " " .. globalInc .. localInc
   end
   if paths == " " then paths = nil end
   paths = str_to_table (paths, resolve ("[%s]+$(lmk.includePathFlag)"))
   if not paths then paths = {} end
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      if not path or path == "" then path = "./" end
      path = abs_path (path)
      if path then paths[#paths + 1] = path .. "/" end
      local objectTarget = resolve ("$(localTmpDir)".. file .. "$(lmk.objExt)")
      set ("objectTarget", objectTarget)
      objList[#objList + 1] = file .. resolve "$(lmk.objExt)"
      local build = false
      if file_newer (item, objectTarget) then build = true
      elseif header_newer (item, file, ext, paths) then build = true
      end
      if path then table.remove (paths) end
      if build then
         set ("file", item)
         execList[#execList + 1] = resolve (execVar)
      end
   end
   return execList, objList
end

function clean_obj (files)
   local objList = {}
   for index, item in ipairs (files) do
      local path, file, ext = split (item)
      local result = resolve ("$(localTmpDir)".. file .. "$(lmk.objExt)")
      objList[#objList + 1] = resolve (file .. "$(lmk.objExt)")
      rm (result)
      local depend_file = resolve ("$(localTmpDir)".. file .. "." .. ext .. ".depend")
      rm (depend_file)
   end
   add_files (objList, "obj")
end
