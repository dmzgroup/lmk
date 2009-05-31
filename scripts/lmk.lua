require "lmkbase"
require "lmkutil"

-- dependencies
local _G = _G
local assert = assert
local dofile = dofile
local io = io
local ipairs = ipairs
local lmkbase = lmkbase
local lmkutil = lmkutil
local os = os
local pairs = pairs
local pcall = pcall
local print = print
local require = require
local string = string
local table = table
local tostring = tostring
local type = type
local package = package

module (...)

-- local globals
local gProjectName = "lmkproject"
local gLMKFilesName = "lmkfiles.lua"
local gProjectRoot = nil
local gProject = nil
local gEnv = {}
local gPersistEnv = {}
gPersistEnv[lmkbase.system ()] = true
gPersistEnv["platform"] = lmkbase.system ()
local gLocalEnv = {}
local gFiles = {}
local gInProgress = 1
local gBuilt = 2
local gProcessFuncName = "main"
local gRecurse = false

-- exported functions used in lmk files
local function noop () print ("Error: no op function called") end
set_name = noop
set_type = noop
add_files = noop
add_libs = noop
add_preqs = noop
add_vars = noop

-- local functions
local function set_defaults ()
   set_name = function ()
      print ("Error: function 'set_name' not defined")
      os.exit (-1)
   end
   set_type = function ()
      print ("Error: function 'set_type' not defined")
      os.exit (-1)
   end
   add_files = function ()
      print ("Error: function add_files' not defined")
      os.exit (-1)
   end
   add_libs = function ()
      print ("Error: function add_libs' not defined")
      os.exit (-1)
   end
   add_preqs = function ()
      print ("Error: function add_preqs' not defined")
      os.exit (-1)
   end
   add_vars = function ()
      print ("Error: function add_vars' not defined")
      os.exit (-1)
   end
end

local function set_update_funcs (info)
   set_name = function (name) info.name = name end
   set_type = function () end -- noop
   add_files = function () end -- noop
   add_libs = function () end -- noop
   add_preqs = function () end -- noop
   add_vars = function () end -- noop
end

local function validate_flags (flags)
   local result = true
   if flags then
      for index, value in pairs (flags) do
         if gEnv[index] then result = value
         else result = not value
         end
         if not result then break end
      end
   end
   return result
end

local function detect_src_type (files)
   local result = nil
   if files[1] then result = files[1]:match ("\.([%w_]+)$") end
   return result
end

local function append_table (target, add)
   if type (target) == "string" then
      error ("Expect table but was given string: " .. target) end
   local size = #target
   if type (add) ~= "table" then target[size + 1] = add
   else for ix = 1, #add do target[size + ix] = add[ix] end
   end
end

local function add_files_to_info (info, files, src)
   if not src then src = detect_src_type (files) end
   if src then
      if not info.src then info.src = {} end
      if not info.srcIndex then info.srcIndex = {} end
      if not info.src[src] then info.src[src] = {} end
      if not info.src[src].files then
         info.src[src].files = files
         info.src[src].src = src
         info.srcIndex[#(info.srcIndex) + 1] = info.src[src]
      else append_table (info.src[src].files, files)
      end
   else print ("Error: Unable to detect type of file: " .. files[1])
   end
end

local function set_build_funcs (info)
   set_name = function (name, flags)
      if validate_flags (flags) then info.name = name
      else info.name = nil
      end
   end
   set_type = function (name, flags)
      if validate_flags (flags) then info.type = name
      else info.type = nil
      end
   end
   add_files = function (files, flags)
      local src = nil
      if flags and flags.src then src = flags.src; flags.src = nil end
      if validate_flags (flags) then
         add_files_to_info (info, files, src)
      end
   end
   add_libs = function (libs, flags)
      if validate_flags (flags) then
         if not info.libs then info.libs = libs
         else append_table (info.libs, libs)
         end
      end
   end
   add_preqs = function (preqs, flags)
      if validate_flags (flags) then
         if not info.preqs then info.preqs = preqs
         else append_table (info.preqs, preqs)
         end
      end
   end
   add_vars = function (vars, flags)
      if validate_flags (flags) then
         for index, value in pairs (vars) do
            if not info[index] then info[index] = value
            else
               if type (info[index]) ~= "table" then info[index] = { info[index] } end
               append_table (info[index], value)
            end
         end
      end
   end
end

local function find_project_root ()
   lmkutil.pushd ()
   local cwd = lmkutil.pwd ()
   local found = nil
   if cwd then
      local done = false
      while not done do
         if lmkbase.is_valid (gProjectName) then
            found = cwd .. "/"
            done = true
         elseif not lmkbase.cd ("..") then done = true
         else
            local nextDir = lmkutil.pwd ()
            if nextDir == cwd then done = true
            else cwd = nextDir
            end
         end
      end
   end
   lmkutil.popd ()
   return found
end

local function init_project_path (path)
   local result, msg = true, nil
   if not path then path = lmkutil.pwd () end
   result, msg = lmkutil.pushd (path)
   if result then
      local root = find_project_root ()
      if root then
         gProjectRoot = root 
         gProject = root .. gProjectName .. "/"
      else
         result = false
        msg = "Unable to find project starting in path: " .. lmkutil.pwd ()
      end
      lmkutil.popd ()
   end
   return result, msg
end

local function add_lmk_files (path, table)
   local result = ""
   lmkbase.cd (path)
   local files = lmkbase.files (path)
   if files then
      local luaFound = false
      local luaPathFound = path:find ("lmk/$", -4)
      for ix, element in ipairs (files) do
         if element:find ("%.lmk$", -4) then
            table[#table + 1] = { path = path, file = element }
         elseif luaPathFound and element:find ("%.lua$", -4) then luaFound = true
         end
      end
      if luaFound then result = path .. "?.lua;" end
   end
   local dirs = lmkbase.directories (path)
   if dirs then
      for ix, element in ipairs (dirs) do
         result = result .. add_lmk_files (path .. element .. "/", table)
      end
   end
   return result
end

local build_depends = nil -- forward declaration of function`

local function process_info (info)
   local result, msg = true, nil
   gLocalEnv = info
   require "lmkpreprocess"
   info.localPwd = lmkutil.pwd ()
   if _G.lmkpreprocess[gProcessFuncName] then
      _G.lmkpreprocess[gProcessFuncName] ()
   end
   if info.srcIndex then
      local count = 1
      local done = false
      while not done do
         local data = info.srcIndex[count]
         if data then
            if data.src then
               require (data.src)
               if not result then done = true
               elseif _G[data.src] and _G[data.src][gProcessFuncName] then
-- Moved up where it will always be set
--                  info.localPwd = lmkutil.pwd ()
                  _G[data.src][gProcessFuncName] (data.files)
                  if not result then done = true end
               end
            end
            count = count + 1
         else done = true
         end
      end
   end
   require "lmkpostprocess"
   if _G.lmkpostprocess[gProcessFuncName] then
      _G.lmkpostprocess[gProcessFuncName] ()
   end
   gLocalEnv = nil
   return result, msg
end

local function exec_lmk_file (path, file)
   print ("Processing: " .. file)
   local result, msg = lmkutil.pushd (path)
   if result then
      local info = {}
      set_build_funcs (info)
      dofile (file)
      if info.name then
         gEnv[info.name] = info
         if gFiles[info.name] then
            if not gFiles[info.name].status then
               gFiles[info.name].status = gInProgress
               if result then result, msg = build_depends (info.preqs) end
               if result then result, msg = build_depends (info.libs) end
               if result then
                  result, msg = process_info (info)
                  if result then gFiles[info.name].status = gBuilt end
               end
               if not result then
                  msg = msg .. " in: " ..
                     gFiles[info.name].path .. gFiles[info.name].file
               end
            elseif gFiles[info.name].status == gBuilt then
            elseif gFiles[info.name].status == gInProgress then
               result = false
               msg = "Circular library dependency found in: " ..
                  gFiles[info.name].path .. gFiles[info.name].file
            else
               result = false
               msg = "Unknown build status for: " .. gFiles[info.name].path ..
                  gFiles[info.name].file
            end
         end
      end
      lmkutil.popd ()
   end
   return result, msg
end

build_depends = function (depends)
   local result, msg = true, nil
   if (depends) then
      for ix = 1, #depends do
         local data = gFiles[depends[ix]]
         if data then
            if data.status == gBuilt then -- do nothing
            elseif data.status == gInProgress then
               result = false
               msg = "Circular library dependency found in: " .. data.path ..
                  data.file
               break
            else result, msg = exec_lmk_file (data.path, data.file)
            end
         else
            result = false
            msg = "Unknown dependency: " .. depends[ix]
            break
         end
      end
   end
   return result, msg
end

-- Exported functions

function set_global_env (globals)
   gEnv = globals
   for index, value in pairs (gPersistEnv) do gEnv[index] = value end
end

function set_lmkfiles (files)
   gFiles = files
end

local originalSearchPath = package.path
if not originalSearchPath then originalSearchPath = "" end

function set_luapath (path)
   package.path = path .. originalSearchPath
end

function update (path)
   if not path then path = gProjectRoot and gProjectRoot or lmkutil.pwd () end
   local result, msg = init_project_path (path)
   if result and lmkutil.pushd (gProjectRoot) then
      local files = {}
      local searchPath = add_lmk_files (gProjectRoot, files)
      if searchPath and searchPath:len () > 0 then set_luapath (searchPath) end
      local info = {}
      local list = {}
      set_update_funcs (info)
      for ix, element in ipairs (files) do
         info.name = nil
         dofile (element.path .. element.file)
         if info.name then
            if not list[info.name] then list[info.name] = element
            else
               result = false
               msg = "Error: Name " .. "'" .. info.name ..
                  "' is not unique. Found in:\n" ..
                  "      '" .. element.path .. "/" .. element.file .. "'\n" ..
                  "      '" .. list[info.name].path .. "/" .. element.file ..
                  "'"
            end
         end
      end
      if result then
         local outName = gProject .. gLMKFilesName
         local out = io.open (outName, "w+")
         if out then
            if searchPath and searchPath:len () > 0 then
               out:write ('lmk.set_luapath ("' .. searchPath .. '")\n')
            end
            out:write ("lmk.set_lmkfiles ({\n")
            for index, element in pairs (list) do
               print (index .. " = " .. element.path .. "/" .. element.file)
               out:write ("\n   " .. index .. " = {\n")
               out:write ("      path = \"" .. element.path .. "\",\n")
               out:write ("      file = \"" .. element.file .. "\"\n   },\n")
            end
            out:write ("})\n")
            out:close ()
         else
            result = false
            msg = "Error: unable to create file '" .. outName .. "'"
         end
      end
      lmkutil.popd ()
   end
   return result, msg
end

function init (path)
   if not path then path = gProjectRoot and gProjectRoot or lmkutil.pwd () end
   local result, msg = init_project_path (path)
   if result then
      set_defaults ()
      local global = gProject .. "/" .. "global.lua"
      local lmkfiles = gProject .. "/" .. gLMKFilesName
      gEnv = nil
      if lmkbase.is_valid (global) then
         result, msg = pcall (dofile, global)
         if not gEnv then set_global_env ({}) end
      else set_global_env ({})
      end
      if not gEnv.lmk then gEnv.lmk = {} end
      gEnv.lmk.projectRoot = gProjectRoot 
      if result and
            (not lmkbase.is_valid (lmkfiles) or
               not pcall (dofile, lmkfiles)) then
         result, msg = update ()
         if result then result, msg = pcall (dofile, lmkfiles) end
      end
   end
   return result, msg
end

function set_process_func_name (name)
   gProcessFuncName = name
   print ("Setting process function name to: " .. gProcessFuncName);
end

function set_build_mode (name)
   set_global ("lmk.buildMode", name, true)
   local currentMode = gPersistEnv.currentBuildMode
   if currentMode then
      -- remove previous build mode value.
      gPersistEnv[currentMode] = nil
      gEnv[currentMode] = nil
   end
   gPersistEnv.currentBuildMode = name
   set_global (name, true, true)
end

function set_recurse (recurse)
   if recurse then gRecurse = true
   else gRecurse = false
   end
end

local function build_dir (path, recurse)
   local result, msg = true, nil
   if recurse then
      local paths = lmkbase.directories (path)
      if paths then
         for _, element in ipairs (paths) do
            result, msg = build_dir (path .. "/" .. element, recurse)
            if not result then break end
         end
      end
   end
   if result then
      local files = lmkbase.files (path)
      if files then
         for ix, element in ipairs (files) do
            if element:find ("\.lmk$", -4) then
               local dir, file, ext = lmkutil.raw_split (element)
               if ext == "lmk" then
                  result, msg = exec_lmk_file (path, file .. "." .. ext)
               else
                  result = false
                  msg = "File: " .. path .. "/" .. element .. " is not an lmk file"
               end
            end
         end
      end
   end
   return result, msg
end

function build (path)
   local result, msg = init (path)
   if result then
      local isDir = path and lmkbase.is_dir (path) or false
      if lmkutil.pushd (path and path or gProjectRoot) then
         require "lmkprebuild"
         if _G.lmkprebuild[gProcessFuncName] then
            _G.lmkprebuild[gProcessFuncName] ()
         end
         if path then
            if isDir then result, msg = build_dir (".", gRecurse)
            else
               local dir, file, ext = lmkutil.raw_split (path)
               if ext == "lmk" then
                  result, msg = exec_lmk_file (dir, file .. "." .. ext)
               else
                  result = false
                  msg = "File: " .. path .. " is not an lmk file"
               end
            end
         else
            for index, value in pairs (gFiles) do
               if not value.status then
                  result, msg = exec_lmk_file (value.path, value.file)
                  if not result then break end
               elseif value.status == gBuilt then
               elseif value.status == gInProgess then
                  result = false
                  msg = "Circular library dependency found in: " ..
                     value.path .. "/" .. value.file
               else
                  result = false
                  msg = "Unknown build status error in: " ..
                     value.path .. "/" .. value.file
               end
            end
         end
         require "lmkpostbuild"
         if result and _G.lmkpostbuild[gProcessFuncName] then
            _G.lmkpostbuild[gProcessFuncName] ()
         end
         lmkutil.popd ()
      else
         result, msg = false, "Unable to build path: " .. 
            (path and path or gProjectRoot)
      end
   end
--lmkutil.dump_table ("gEnv", gEnv)
   return result, msg
end

local function break_scope (name)
   local scope = {}
   for item in name:gfind ("([^.]+)") do scope[#scope + 1] = item end
   return scope
end

local function find_data (env, data)
   local scope = break_scope (data)
   if env and scope then
      for ix = 1, #scope do
         env = env[scope[ix]]
         if not env then break end
      end
   end
   return env
end

resolve = nil

local function sub_var (str)
   local result = resolve (str:sub (2, -2)) --strip off the parentheses
   local data = nil
   if result ~= "" then
      data = find_data (gLocalEnv, result)
      if not data then data = find_data (gEnv, result) end
   end
   local dt = type (data)
   if dt == "table" then
      result = ""
      local size = #data
      for ix = 1, size do
         if data[ix] then
            local item = resolve (data[ix])
            if item ~= "" then result = result .. (ix == 1 and "" or " ") .. item end
         end
      end
   elseif dt == "string" and (result ~= "") then result = resolve (data)
   else result = ""
   end
   return result
end

resolve = function (str)
   if str then
if type (str) == "table" then lmkutil.dump_table ("unknown", str) end
assert (type (str) == "string", "str is not a string: " .. type (str))
      str = str:gsub ("%$(%b())", sub_var)
   end
   return str
end

local function find_env (env, name)
   scope = break_scope (name)
   if env and scope then
      for ix = 1, #scope - 1 do
         if not env[scope[ix]] then env[scope[ix]] = {} end
         env =  env[scope[ix]]
      end
   end
   return env, scope[#scope]
end

local function set_var (env, name, value)
   env, name = find_env (env, name)
   if env then env[name] = value end
end

local function append_var (env, name, value)
   env, name = find_env (env, name)
   if env and value then
      if not env[name] then env[name] = ((type (value) == "table") and value or { value })
      else
         if type (env[name]) ~= "table" then env[name] = { env[name] } end
         if type (value) ~= "table" then value = { value } end
         append_table (env[name], value)
      end
   end
end

function set_local (name, value)
   set_var (gLocalEnv, name, value)
end

function set_global (name, value, persist)
   if persist then set_var (gPersistEnv, name, value) end
   set_var (gEnv, name, value)
end

function append_local (name, value)
   append_var (gLocalEnv, name, value)
end

function append_global (name, value, persist)
   if persist then append_var (gPersistEnv, name, value) end
   append_var (gEnv, name, value)
end

function get_var (name)
   local result = nil
   if gLocalEnv then result = find_data (gLocalEnv, name) end
   if result == nil and gEnv then result = find_data (gEnv, name) end
   if result ~= nil and type (result) ~= "table" then result = { result } end
   return result
end

function add_files_local (files, src)
   add_files_to_info (gLocalEnv, files, src)
end

local gSystem = lmkbase.system ()
function set_system (system)
   gPersistEnv[lmkbase.system ()] = nil
   gSystem = system
   gPersistEnv["platform"] = gSystem
   gPersistEnv[gSystem] = true
end

function system ()
   return gSystem
end

function merge_tables (t1, t2)
    if type (t1) == "table" and type (t2) == "table" then
      for index, value in pairs (t2) do
         t1[index] = value
      end
   elseif type (t1) ~= "table" then t1 = {}
   end
   return t1
end
