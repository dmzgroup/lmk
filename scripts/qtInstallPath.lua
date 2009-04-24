require "lmkbase"
require "lmkutil"

local files = lmkbase.files (".")
--[[
local list = {
{ "libQtAssistantClient.4.dylib", "@executable_path/../Frameworks/Qt/QtAssistantClient"},
{ "libQtCore.4.dylib", "@executable_path/../Frameworks/Qt/QtCore"},
{ "libQtDesigner.4.dylib", "@executable_path/../Frameworks/Qt/QtDesigner"},
{ "libQtDesignerComponents.4.dylib", "@executable_path/../Frameworks/Qt/QtDesignerComponents"},
{ "libQtGui.4.dylib", "@executable_path/../Frameworks/Qt/QtGui"},
{ "libQtNetwork.4.dylib", "@executable_path/../Frameworks/Qt/QtNetwork"},
{ "libQtOpenGL.4.dylib", "@executable_path/../Frameworks/Qt/QtOpenGL"},
{ "libQtScript.4.dylib", "@executable_path/../Frameworks/Qt/QtScript"},
{ "libQtSql.4.dylib", "@executable_path/../Frameworks/Qt/QtSql"},
{ "libQtSvg.4.dylib", "@executable_path/../Frameworks/Qt/QtSvg"},
{ "libQtTest.4.dylib", "@executable_path/../Frameworks/Qt/QtTest"},
{ "libQtXml.4.dylib", "@executable_path/../Frameworks/Qt/QtXml"},
}
]]--

local list = {
{ "QtAssistant.framework/Versions/4/QtAssistant", "@executable_path/../Frameworks/Qt/QtAssistant"},
{ "QtCore.framework/Versions/4/QtCore", "@executable_path/../Frameworks/Qt/QtCore"},
{ "QtDesigner.framework/Versions/4/QtDesigner",
  "@executable_path/../Frameworks/Qt/QtDesigner"},
{ "QtDesignerComponents.framework/Versions/4/QtDesignerComponents",
  "@executable_path/../Frameworks/Qt/QtDesignerComponents"},
{ "QtGui.framework/Versions/4/QtGui", "@executable_path/../Frameworks/Qt/QtGui"},
{ "QtHelp.framework/Versions/4/QtHelp", "@executable_path/../Frameworks/Qt/QtHelp"},
{ "QtNetwork.framework/Versions/4/QtNetwork",
  "@executable_path/../Frameworks/Qt/QtNetwork"},
{ "QtOpenGL.framework/Versions/4/QtOpenGL", "@executable_path/../Frameworks/Qt/QtOpenGL"},
{ "QtScript.framework/Versions/4/QtScript", "@executable_path/../Frameworks/Qt/QtScript"},
{ "QtScriptTools.framework/Versions/4/QtScriptTools", "@executable_path/../Frameworks/Qt/QtScriptTools"},
{ "QtSql.framework/Versions/4/QtSql", "@executable_path/../Frameworks/Qt/QtSql"},
{ "QtSvg.framework/Versions/4/QtSvg", "@executable_path/../Frameworks/Qt/QtSvg"},
{ "QtTest.framework/Versions/4/QtTest", "@executable_path/../Frameworks/Qt/QtTest"},
{ "QtWebKit.framework/Versions/4/QtWebKit", "@executable_path/../Frameworks/Qt/QtWebKit"},
{ "QtXml.framework/Versions/4/QtXml", "@executable_path/../Frameworks/Qt/QtXml"},
{ "phonon.framework/Versions/4/phonon", "@executable_path/../Frameworks/Qt/phonon"},
}

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

files = lmkbase.files (".")

for index, file in ipairs (files) do
   local id = "install_name_tool -id @executable_path/../Frameworks/Qt/" .. file .. " " .. file
   os.execute (id)
   for _, value in ipairs (list) do
      local arg = "install_name_tool -change " .. value[1] .. " " .. value[2] .. " " .. file
      os.execute (arg)
   end
end
