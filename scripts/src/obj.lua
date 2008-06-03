require "lmkbuild"

local append = lmkbuild.append_local
local exec = lmkbuild.exec
local file_newer = lmkbuild.file_newer
local function gset (name, value)
   lmkbuild.set_global (name, value, true)
end
local get_var = lmkbuild.get_var
local ipairs = ipairs
local is_valid = lmkbuild.is_valid
local print = print
local resolve = lmkbuild.resolve
local rm = lmkbuild.rm
local set = lmkbuild.set_local
local sys = lmkbuild.system ()
local table = table

if sys == "win32" then
   gset ("lmk.link", {
      "$(lmk.$(type).linker.$(lmk.buildMode))",
      "$(lmk.$(type).linkerFlags)",
      "$(lmk.$(lmk.buildMode).linkerFlags)",
      "$(localLibPaths)",
      "$(lmk.libPaths)",
      "$(localLibs)",
      "$(objList)",
      "$(lmk.$(type).extraFiles)",
      "/out:$(localBinTarget)",
   })
   gset ("lmk.libPathFlag", "/LIBPATH:")
   gset ("lmk.libSuffix", ".lib")
   gset ("lmk.shared.prefix", "")
   gset ("lmk.shared.ext", ".dll")
   gset ("lmk.plugin.ext", ".dll")
   gset ("lmk.exe.ext", ".exe")
   local linker = "link.exe"
   local bclinker = "nmlink.exe bcinterf.lib"
   gset ("lmk.exe.linker.opt", linker)
   gset ("lmk.exe.linker.debug", linker)
   gset ("lmk.exe.linker.bc", bclinker)
   gset ("lmk.exe.linkerFlags", "/nologo")
   gset ("lmk.shared.linker.opt", linker)
   gset ("lmk.shared.linker.debug", linker)
   gset ("lmk.shared.linker.bc", bclinker)
   gset ("lmk.shared.linkerFlags", "/nologo /DLL")
   gset ("lmk.shared.extraFiles", "/IMPLIB:$(lmk.libDir)$(name)$(lmk.libSuffix)")
   gset ("lmk.plugin.linker.opt", linker)
   gset ("lmk.plugin.linker.debug", linker)
   gset ("lmk.plugin.linker.bc", bclinker)
   gset ("lmk.plugin.linkerFlags", "/nologo /DLL")
   gset ("lmk.debug.linkerFlags", "/DEBUG /INCREMENTAL:no /FIXED:no")
   gset ("lmk.bc.linkerFlags", "/DEBUG /INCREMENTAL:no /FIXED:no")
   gset ("lmk.bc.testExec", "bc.exe /NOLOGO /W $(localPwd) ")
else -- unix
   gset ("lmk.link", {
      "$(lmk.$(type).linker)",
      "$(lmk.$(type).linkerFlags)",
      "$(localLibPaths)",
      "$(lmk.libPaths)",
      "$(localLibs)",
      "$(objList)",
      "-o $(localBinTarget)",
   })
   gset ("lmk.libPathFlag", "-L")
   gset ("lmk.libPrefix", "-l")
   gset ("lmk.shared.prefix", "lib")
   gset ("lmk.shared.ext", ".so")
   gset ("lmk.plugin.ext", ".plugin")
   if sys == "macos" then
      local linker = "g++ -header_pad_max_install_names"
      local outFlag = "-o "
      gset ("lmk.exe.linker", linker)
      gset ("lmk.shared.linker", linker)
      gset ("lmk.shared.linkerFlags", "-dynamiclib -install_name @executable_path/../Frameworks/$(localBinName)")
      gset ("lmk.shared.ext", ".dylib")
      gset ("lmk.plugin.linker", linker)
      gset ("lmk.plugin.linkerFlags", "-bundle")
   elseif sys == "linux" then
      local linker = "g++"
      local outFlag = "-o "
      gset ("lmk.exe.linker", linker)
      gset ("lmk.shared.linker", linker)
      gset (
         "lmk.shared.linkerFlags",
         "-shared -Xlinker -E -Xlinker -rpath-link -Xlinker $(lmk.binDir)")
      gset ("lmk.plugin.linker", linker)
      gset (
         "lmk.plugin.linkerFlags",
         "-shared -Xlinker -E -Xlinker -rpath-link -Xlinker $(lmk.binDir)")
      gset (
         "lmk.exe.linkerFlags",
         "-Xlinker -rpath-link -Xlinker $(lmk.binDir)")
   end
end

module (...)

function main (files)
   local binName =
      resolve ("$(lmk.$(type).prefix)$(name)$(lmk.$(type).ext)")
   set ("localBinName", binName)
   local binTarget =
      resolve ("$(lmk.binDir)" .. binName)
   set ("localBinTarget", binTarget)
   local build = false
   if not is_valid (binTarget) then build = true
   else
      local objFiles = {}
      local tmpDir = resolve "$(localTmpDir)"
      for index, item in ipairs (files) do
         objFiles[index] = tmpDir .. item
      end
      if file_newer (objFiles, binTarget) then build = true end
   end
   if build then
      if sys == "win32" then
         append ("localLibPaths", "$(lmk.libPathFlag)$(localTmpDir)")
         set ("objList", files)
      else
         local objList = {}
         for ix, item in ipairs (files) do
            objList[#objList + 1] = "$(localTmpDir)" .. item
         end
         set ("objList", objList)
      end
      local libs = get_var ("libs")
      if libs then
         local libList = {}
         for index, item in ipairs (libs) do
            libList[index] = "$(lmk.libPrefix)" .. item .. "$(lmk.libSuffix)"
         end
         append ("localLibs", libList)
      end
      exec ("$(lmk.link)")
      if sys == "win32" then
         local mt = "mt.exe -nologo -manifest " .. binTarget .. ".manifest -outputresource:" .. binTarget .. ";"
         if resolve ("$(type)") == "exe" then mt = mt .. "1" else mt = mt .. "2" end
         exec (mt)
      end
   end
end

function test (files)
   main (files)
   local testDefined = resolve ("$(test)")
   if testDefined ~= "" then exec ("$(lmk.$(lmk.buildMode).testExec)$(test)") end
end

function clobber (files)
   local binTarget =
      resolve ("$(lmk.binDir)$(lmk.$(type).prefix)$(name)$(lmk.$(type).ext)")
   rm (binTarget)
   -- will need to remove windows specific files here
end
