require "lmkbase"
require "lmkutil"

local files = lmkbase.files (".")

local OldPath = ".framework/Versions/4/"
local NewPath = "@executable_path/../Frameworks/Qt/"

local libs = {
   "QtAssistant",
   "QtCore",
   "QtDesigner",
   "QtDesignerComponents",
   "QtGui",
   "QtHelp",
   "QtNetwork",
   "QtOpenGL",
   "QtScript",
   "QtScriptTools",
   "QtSql",
   "QtSvg",
   "QtTest",
   "QtWebKit",
   "QtXml",
   "phonon",
}

local list = {}

for _, lib in ipairs (libs) do
   list[#list + 1] = {lib .. OldPath .. lib, NewPath .. lib}
end

files = lmkbase.files (".")

for index, file in ipairs (files) do
   local id = "install_name_tool -id @executable_path/../Frameworks/Qt/" .. file .. " " .. file
   os.execute (id)
   for _, value in ipairs (list) do
      local arg = "install_name_tool -change " .. value[1] .. " " .. value[2] .. " " .. file
      print (arg)
      os.execute (arg)
   end
end

--[[

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

local function mv (src, target)
   if lmkbase.is_valid (src) and not lmkbase.is_dir (src) then
      if lmkbase.is_dir (target) then
         local path, file = lmkutil.split_path_and_file (src)
         if file then target = target .. file
         else target = nil
         end
      end
   end
   if target then 
      copy_file (src, target)
      if lmkbase.is_valid (target) then lmkbase.rm (src) end
   end
   return target
end

for index, file in ipairs (files) do
   local name = file:match ("lib(Qt[%w]+).4.3.4.dylib")
   if name then mv (file, name) end
end

--]]

