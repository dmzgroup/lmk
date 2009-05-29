require "lmkbuild"

local add_files = lmkbuild.add_files
local error = error
local file_newer = lmkbuild.file_newer
local get = lmkbuild.get_var
local io = io
local ipairs = ipairs
local is_valid = lmkbuild.is_valid
local print = print
local resolve = lmkbuild.resolve
local rm = lmkbuild.rm
local set = lmk.set_local
local split = lmkbuild.split
local table = table
local tostring = tostring

module (...)

function main (files)
   local name = resolve ("$(embedName)")
   if (not name) or (name == "") then name = resolve ("$(name)") end
   local root = resolve ("$(embedRoot)")
   if (not root) or (root == "")  then root = name end
   local countFunc = "get_" .. root .. "_count"
   local getFunc = "get_" .. root .. "_text"
   local fileFunc = "get_" .. root .. "_file_name"
   local target = name .. ".h"
   if file_newer (files, target) then
      fout = io.open (target, "w")
      if fout then
         local macroName = name:gsub ("(%w)(%u%l)", "%1_%2"):
            gsub ("(%l)(%u)", "%1_%2"):upper ()
         local macroHeader = macroName .. "_DOT_H"
         local macroExport = macroName .. "_EXPORT"
         local macroLink = macroName .. "_LINK_SYMBOL"
         fout:write ("// WARNING: Auto Generated File. DO NOT EDIT.\n\n")
         fout:write ("#ifndef " .. macroHeader .. "\n")
         fout:write ("#define " .. macroHeader .. "\n\n")
         fout:write ("#include <dmzTypesBase.h>\n\n")
         fout:write ("#ifdef _WIN32\n")
         fout:write ("#   ifdef " .. macroExport .. "\n")
         fout:write ("#      define " .. macroLink .. " __declspec (dllexport)\n")
         fout:write ("#   else\n")
         fout:write ("#      define " .. macroLink .. " __declspec (dllimport)\n")
         fout:write ("#   endif\n")
         fout:write ("#else\n")
         fout:write ("#      define " .. macroLink .. "\n")
         fout:write ("#endif\n\n")
         fout:write ("namespace dmz {\n\n")
         fout:write (macroLink .. " Int32\n")
         fout:write (countFunc .. " ();\n\n")
         fout:write (macroLink .. " const char*\n")
         fout:write (getFunc .. " (const Int32 Which);\n\n")
         fout:write (macroLink .. " const char*\n")
         fout:write (fileFunc .. " (const Int32 Which);\n\n")
         fout:write ("};\n\n")
         fout:write ("#endif // " .. macroHeader .. "\n")
         io.close (fout)
         add_files {target}
      end
   end
   target = name .. ".cpp"
   if file_newer (files, target) then
      local fout = io.open (target, "w")
      if fout then
         fout:write ("// WARNING: Auto Generated File. DO NOT EDIT.\n\n")
         fout:write ("#include <" .. name .. ".h>\n\n")
         fout:write ("#include <dmzTypesBase.h>\n\n")
         fout:write ("namespace {\n\n")
         for index, inFile in ipairs (files) do
            local count = 0
            fout:write ("// " .. inFile .. "\n")
            fout:write ("static const char data" .. index .. "[] = {\n")
            local instr = nil
            local fin = io.open (inFile, "r")
            if fin then
               instr = fin:read ("*all")
               io.close (fin)
            else error ("Unable to open file: " .. inFile .. " for embedding.")
            end
            if instr then
               local length = instr:len ()
               for ix = 1, length do
                  local byte = instr:byte (ix)
                  if byte < 10 then fout:write ("  ")
                  elseif byte < 100 then fout:write (" ")
                  end
                  fout:write (tostring (byte))
                  count = count + 1
                  if count > 17 then
                     count = 0
                     fout:write (",\n")
                  else
                     fout:write (", ")
                  end
               end
            end
            fout:write ("  0\n};\n\n")
         end
         fout:write ("};\n\n\n")
         fout:write ("dmz::Int32\n")
         fout:write ("dmz::".. countFunc .. " () { return " .. tostring (#files) ..
            "; }\n\n\n")
         fout:write ("const char *\n")
         fout:write ("dmz::" .. getFunc .. " (const Int32 Which) {\n\n")
         fout:write ("   switch (Which) {\n")
         for ix = 1, #files do
            fout:write ("      case " .. tostring (ix - 1) .. ": return data" ..
               tostring (ix) .. "; break;\n")
         end
         fout:write ("      default: return 0;\n")
         fout:write ("   }\n\n   return 0;\n}\n\n\n")
         fout:write ("const char *\n")
         fout:write ("dmz::" .. fileFunc .. " (const Int32 Which) {\n\n")
         fout:write ("   switch (Which) {\n")
         for index, inFile in ipairs (files) do
            fout:write ("      case " .. tostring (index - 1) .. ': return "' ..
               inFile .. '"; break;\n')
         end
         fout:write ("      default: return 0;\n")
         fout:write ("   }\n\n   return 0;\n}\n\n\n")
         io.close (fout)
         add_files {target}
      else error ("Unable to create file: " .. target)
      end
   end
end

function test (files)
   main (files)
end

function clean (files)
end

function clobber (files)
end
