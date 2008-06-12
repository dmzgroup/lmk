--[[
{
   {
      name = "lib name",
      unique = "unique name",
      factory = "factory name",
      nodelete = true,
      level = { 1, 2, 5, 6 },
   },
}
--]]

local function create_plugin (file, list)

   local fstr = "void\ndmz_create_plugins (\n" ..
      "      dmz::RuntimeContext *context,\n" ..
      "      dmz::Config &config,\n" ..
      "      dmz::Config &global,\n" ..
      "      dmz::PluginContainer &container) {\n\n" ..
      "   dmz::PluginInfo *info (0);\n" ..
      "   dmz::Config local;"
print ()
print (fstr)
   for _, value in ipairs (list) do
      local infoStr = '   info = new dmz::PluginInfo ("' .. value.unique .. '", '
      if value.delete then infoStr = infoStr .. "PluginDeleteModeDelete, "
      else infoStr = infoStr .. "PluginDeleteModeDoNotDelete, "
      end
      infoStr = infoStr .. "context, 0);"
      local lstr = "   local.set_config_context (0);\n" ..
        "   config.lookup_all_config_merged (" ..
        '"' .. value.unique .. '", ' ..  "local);"
      local storeStr = "   container.add_plugin (info, " ..
         value.factory .. " (*info, local, global));"
print ("")
print (infoStr)
print (lstr)
print (storeStr)
   end
print ("}")
end

local function create_extern (file, list)
   local istr =
      "#include <dmzRuntimeConfig.h>\n"..
      "#include <dmzRuntimePlugin.h>\n"..
      "#include <dmzRuntimePluginContainer.h>\n"..
      "#include <dmzRuntimePluginInfo.h>\n"
print (istr)
print ('extern "C" {')
   for _, value in ipairs (list) do
      local str = "dmz::Plugin *" .. value.factory ..
         " (const dmz::PluginInfo &Info, dmz::Config &local, dmz::Config &global);"
print (str)
   end
print ("}")
end

local function validate_list (list)
   for _, value in ipairs (list) do
      if not value.name then error ("Name not defined") end
      if not value.unique then value.unique = value.name end
      if not value.factory then value.factory = "create_" .. value.name end
      if not value.delete then value.delete = true end
      if not value.level then value.level = { 1 } end
   end
end

if type (arg[1]) == "string" then
   local list = dofile (arg[1])
   if type (list) == "table" then
      validate_list (list)
      create_extern (nil, list)
      create_plugin (nil, list)
   end
end
