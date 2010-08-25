require "lmk"
require "lmkutil"
require "lmkbase"

local assert = assert
local error = error
local io = io
local ipairs = ipairs
local lmk = lmk
local lmkbase = lmkbase
local lmkutil = lmkutil
local os = os
local print = print
local tostring = tostring
local type = type

module (...)

add_files = lmk.add_files_local
append_global = lmk.append_global
append_local = lmk.append_local
get_var = lmk.get_var
resolve = lmk.resolve
set_local = lmk.set_local
set_global = lmk.set_global
system = lmk.system
is_dir = lmkbase.is_dir
directories = lmkbase.directories
files = lmkbase.files

function print_success (msg)
   lmk.console_green ()
   print (msg)
   lmk.console_default ()
end

function print_fail (msg)
   lmk.console_red ()
   print (msg)
   lmk.console_default ()
end

function verbose () return lmk.IsVerbose end

local buildPart1 = nil
local buildPart2 = nil

function get_build_number ()
   if not buildPart1 or not buildPart2 then
      buildPart1 = os.date ("!%y%m%d")
      buildPart2 = os.date ("!%H%M%S")
   end
   return
      tostring (buildPart1) .. "-" .. tostring (buildPart2),
      tostring (buildPart1),
      tostring (buildPart2)
end

function append_table (target, add)
   if type (target) ~= "table" then
      error ("Expect table but was given: " .. type (target)) end
   local size = #target
   if type (add) ~= "table" then target[size + 1] = add
   else for ix = 1, #add do target[size + ix] = add[ix] end
   end
end

function set_persist (name, value) set_global (name, value, true) end

function rm (path)
   path = lmkutil.clean_path (lmk.resolve (path))
   local result, msg = true, nil
   if lmkbase.is_valid (path) then
      print ("Removing: " .. path)
      result, msg = lmkutil.raw_rm (path)
   end
   return result, msg
end

function mkdir (path)
   path = lmkutil.clean_path (lmk.resolve (path))
   local result, msg = true, nil
   assert (path ~= "", "Path not defined for lmkbuild.mkdir")
   if path then result, msg = lmkutil.raw_mkdir (path) end
   return result, msg
end

function split (path)
   path = lmkutil.clean_path (lmk.resolve (path))
   local file, ext = nil, nil
   if path then path, file, ext = lmkutil.raw_split (path) end
   return path, file, ext
end

function split_path_and_file (path)
   local file, ext = nil, nil
   path, file, ext = split (path)
   if ext and file then file = file .. "." .. ext end
   return path, file
end

function abs_path (path)
   return lmkutil.raw_abs_path (lmk.resolve (path))
end

local function copy_file (src, target)
   local result = false
   local inp = io.open (src, "rb")
   local out = io.open (target, "wb")
   if inp and out then
      local data = inp:read ("*all")
      out:write (data)
      io.close (inp)
      io.close (out)
      result = true
   end
   return result
end

function cp (fileList, target)
   local result = true
   target = lmkutil.clean_path (lmk.resolve (target))
   if type (fileList) ~= "table" then fileList = { fileList } end
   if lmkbase.is_dir (target) then
      for index, file in ipairs (fileList) do
         file = lmkutil.clean_path (lmk.resolve (file))
         if lmkbase.is_valid (file) then
            local path = nil
            path, fileName = split_path_and_file (file)
            if not copy_file (file, target .. "/" .. fileName) then
               result = false
            end
         end
      end
   else
      if #fileList == 1 then
         local file = lmk.resolve (fileList[1])
         if (lmkbase.is_valid (file)) then
            result = copy_file (file, target)
         else result = false;
         end
      else
         result = false
         msg = "Unable to copy multiple files to single file"
      end
   end
   return result
end

function is_valid (path)
   return lmkbase.is_valid (lmk.resolve (path))
end

function file_newer (src, target)
   local result, msg = false, nil
   target = lmkutil.clean_path (lmk.resolve (target))
   if lmkbase.is_valid (target) then
      if type (src) ~= "table" then src = { src } end
      for index, file in ipairs (src) do
         file = lmkutil.clean_path (lmk.resolve (file))
         if lmkbase.is_valid (file) then
            result = lmkbase.file_newer (file, target)
            if result then break end
         else
            result = true
            print ("Warning: source file: " .. file ..
               " does not exist for target file: " .. target)
            break
         end
      end
   else result = true
   end
   return result, msg
end

function exec (list)
   if type (list) ~= "table" then list = { list } end
   for index, item in ipairs (list) do
      local todo = resolve (item)
      assert (todo and todo ~= "", "Empty exec string from: " .. item)
      if lmk.IsVerbose then
         print (todo)
         local result = os.execute (todo)
         assert (result == 0, "Build failed in " .. lmkbase.pwd ())
      else
         local result = os.execute (todo)
         if result ~= 0 then
            print (todo)
            error ("Build failed in " .. lmkbase.pwd ())
         end
      end
   end
end

function find_file (item, paths)
   local file = lmk.resolve (item)
   if is_valid (file) then file = abs_path (file)
   elseif paths then
      local p, f, e = split (file)
      file = nil
      for ix = 1, #paths do
         local testPath = resolve (paths[ix] .. "/" .. item)
         if is_valid (testPath) then file = abs_path (testPath); break
         else
            testPath = resolve (paths[ix]) .. f .. (e and ("." .. e) or "")
            if is_valid (testPath) then file = abs_path (testPath); break end
         end
      end
   end
   return file
end
