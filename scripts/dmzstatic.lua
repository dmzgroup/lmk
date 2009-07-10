require "xml"

local ListToken = "plugin-list"
local PluginToken = "plugin"

local handler = {

plugins = {},
inList = 0,
inPlugin = 0,

starttag = function (self, val, attrs, startv, endv)
   if val == ListToken then self.inList = self.inList + 1
   end

   if self.inList == 1 and val == PluginToken then
      self.inPlugin = self.inPlugin + 1
      if not attrs.reserve then
         if not attrs.platform or attrs.platform == "iphone" then
            self.plugins[#(self.plugins) + 1] = {
               name = attrs.name,
               factory = attrs.factory,
               file = self.fileName,
            }
         end
      end
   end
end,

endtag = function (self, val, attrs, startv, endv)
   if val == ListToken then self.inList = self.inList - 1
   elseif val == PluginToken then self.inPlugin = self.inPlugin - 1
   end
end,
}

local parser = xmlParser (handler)

for index, fileName in ipairs (arg) do
   handler.fileName = fileName
   local file = io.open (fileName)
   if file then
      print ("Parsing file: " .. fileName)
      parser:parse (file:read ("*a"))
      file:close ()
   else
      print ("Failed loading file: " .. fileName)
   end
end

for index, value in ipairs (handler.plugins) do
   local name = value.name
   if not name then error ("Unnamed plugin in file: " .. tostring (value.file))
   elseif not value.factory then value.factory = "create_" .. name
   end
end

local out = io.open ("dmzSystemDynamicLibraryiPhone.cpp", "w")

if out then

out:write ([[
#include <dmzSystemDynamicLibrary.h>

namespace dmz {

   class Plugin;
   class PluginInfo;
   class Config;
};

extern "C" {

]])

local factoryList = {}
for index, value in ipairs (handler.plugins) do
   if not factoryList[value.factory] then
      factoryList[value.factory] = true
      out:write (
         "extern dmz::Plugin *",
         value.factory,
         " (const dmz::PluginInfo &I, dmz::Config &l, dmz::Config &g);\n")
   end
end

out:write ('\n} // extern "C" \n\n')

out:write ([[
struct dmz::DynamicLibrary::State {
   const DynamicLibraryModeEnum LibMode;
   String name;
   String error;
   State (const DynamicLibraryModeEnum Mode) : LibMode (Mode) {;}
};

void
dmz::DynamicLibrary::dump_loaded (Stream &out) {;}

dmz::DynamicLibrary::DynamicLibrary (
      const String &LibName,
      const DynamicLibraryModeEnum LibMode) : _state (*(new State (LibMode))) {

   _state.name = LibName;
}


dmz::DynamicLibrary::~DynamicLibrary () { delete &_state; }

void *
dmz::DynamicLibrary::get_function_ptr (const String &FunctionName) {

   void *functionPtr (0);

]])

factoryList = {}
local first = true
for index, value in ipairs (handler.plugins) do
   if not factoryList[value.factory] then
      factoryList[value.factory] = true
      if first then out:write ('   if (FunctionName == "') first = false
      else out:write ('   else if (FunctionName == "')
      end
      out:write (
         value.factory,
         '") { functionPtr = (void *)&',
         value.factory,
         "; }\n")
   end
end

out:write ([[

   return functionPtr;
}

dmz::Boolean
dmz::DynamicLibrary::is_loaded () { return True; }


dmz::String
dmz::DynamicLibrary::get_name () { return _state.name; }


dmz::String
dmz::DynamicLibrary::get_error () { return _state.error; }
]])

else error ("Unable to open ouput file")
end
