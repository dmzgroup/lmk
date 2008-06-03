require "lmkbase"

local print = print
local pairs = pairs
local string = string
local tostring = tostring
local type = type
local lmkbase = lmkbase
local table = table

module (...)

local dirStack = {}

function pushd (dir)
   if not dir then dir = "."
   elseif not lmkbase.is_dir (dir) then
      local s = dir:find ("[/\\][%w_%. %-]+$")
      if s then
         if s > 1 then dir = dir:sub (1, s)
         else dir = "."
         end
      else dir = "."
      end
   end
   local result = true
   dirStack[#dirStack + 1] = lmkbase.pwd ()
   if not lmkbase.cd (dir) then
      dirStack[#dirStack] = nil
      result = false
   end
   return result
end

function popd ()
   local result = dirStack[#dirStack]
   if result then
      if not lmkbase.cd (result) then result = nil end
      dirStack[#dirStack] = nil
   end
   return result
end

function clean_path (path)
   local result = nil
   if path then
      path = path:gsub ("[/]+", "/")
      result = path:gsub ("[\\]+", "/")
   end
   return result
end

function pwd ()
   return clean_path (lmkbase.pwd ())
end

function break_path (path)
   path = clean_path (path)
   result = nil
   if path then
      result = {}
      for item in path:gfind ("([^/]+)") do
         result[#result + 1] = item
      end
   end
   return result
end

function raw_rm (path)
   local result = true
   if lmkbase.is_dir (path) then
      local dirs = lmkbase.directories (path)
      for ix = 1, #dirs do
         local rmPath = clean_path (path .. "/" .. dirs[ix])
         if rmPath then result = raw_rm (rmPath)
         else result = false; break
         end
      end
      local files = lmkbase.files (path)
      for ix = 1, #files do
         local rmFile = clean_path (path .. "/" .. files[ix])
         if rmFile then result = lmkbase.rm (rmFile)
         else result = false; break
         end
      end
   end
   result = lmkbase.rm (path)
   return result
end

function raw_mkdir (path)
   local result = true
   if not lmkbase.is_valid (path) then
print ("mkdir path: " .. path)
      local root = false
      local slash =  path:sub (1, 1)
      if (slash == "/") or (slash == "\\") then root = true end
      local pathParts = break_path (path)
      if pathParts then
         local newPath = (root and "/" or "")
         for ix = 1, #pathParts do
            newPath = newPath .. pathParts[ix] .. "/"
            if not lmkbase.is_valid (newPath) then
               result = lmkbase.mkdir (newPath)
               if not result then break end
            end
         end
      end
   end
   return result
end

function raw_split (path)
   local file, ext = nil, nil
   local root = false
   local value = path:sub (1, 1)
   if (value == "/") or (value == "\\") then root = true end
   local result = break_path (path)
   if result then
      file = table.remove (result)
      path = (root and "/" or "") .. table.concat (result, "/")
      ext = file:match ("%.([%w_]+)$")
      if ext then file = file:sub (1, #file - (#ext + 1)) end
      if file == ext then ext = nil end
   end
   return path, file, ext
end

function raw_abs_path (path)
   local result = nil
   if lmkbase.is_valid (path) then
      local file, ext = nil, nil
      if not lmkbase.is_dir (path) then path, file, ext = raw_split (path) end
      if not path or path == "" then result = lmkbase.pwd ()
      elseif pushd (path) then
         result  = lmkbase.pwd ()
         popd ()
      end
      if result and file then
         result = clean_path (result .. "/" .. file ..
            (ext and ("." .. ext) or ""))
      end
   end
   return result
end

function process_args (args)
   local list = nil
   for ix = 1, #args do
      if not list then list = {} end
      if args[ix]:sub (1, 1) == "-" then
         list[#list + 1] = { opt = args[ix] }
      elseif list[#list] then
         if not list[#list].values then list[#list].values = {} end
         list[#list].values[#(list[#list].values) + 1] = args[ix]
      else
      end
   end
   return list
end

function dump_table (name, value, indent)
   if not indent then indent = 0 end
   if type (value) == "table"  then
      print (string.rep (" ", indent) .. name .. " = {")
      for index, data in pairs (value) do
         dump_table (index, data, indent + 3)
      end
     print (string.rep (" ", indent) .. "}")
   else print (string.rep (" ", indent) .. name .. " = " ..  tostring (value))
   end
end

function clear_table (value)
   while table.remove (value) do end
end
