require "lmkbase"
require "lmkutil"

local OldPath = "/Users/barker/3rdparty/OpenSceneGraph-2.8.3/lib/Release/"
local NewPath = "@executable_path/../Frameworks/osg/"
local libs = {
"libOpenThreads.dylib",
"libosg.dylib",
"libosgAnimation.dylib",
"libosgDB.dylib",
"libosgFX.dylib",
"libosgGA.dylib",
"libosgManipulator.dylib",
"libosgParticle.dylib",
"libosgPresentation.dylib",
"libosgShadow.dylib",
"libosgSim.dylib",
"libosgTerrain.dylib",
"libosgText.dylib",
"libosgUtil.dylib",
"libosgViewer.dylib",
"libosgVolume.dylib",
"libosgWidget.dylib",
}

local list = {}

for _, lib in ipairs (libs) do
   list[#list + 1] = {OldPath .. lib, NewPath .. lib}
end

local files = lmkbase.files (".")

for index, file in ipairs (files) do
   local id = "install_name_tool -id @executable_path/../Frameworks/osg/" .. file .. " " .. file
   os.execute (id)
   for _, value in ipairs (list) do
      local arg = "install_name_tool -change " .. value[1] .. " " .. value[2] .. " " .. file
      os.execute (arg)
   end
end
