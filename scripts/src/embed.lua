require "lmkbuild"

local add_files = lmkbuild.add_files
local error = error
local file_newer = lmkbuild.file_newer
local get_var = lmkbuild.get_var
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
local type = type

module (...)

function main (files)
   local name = resolve ("$(embedName)")
   if (not name) or (name == "") then name = resolve ("$(name)") end
   local root = resolve ("$(embedRoot)")
   if (not root) or (root == "")  then root = name end
   local ns = resolve ("$(embedNamespace)")
   local useNs = (ns ~= "")
   local export = get_var ("embedExport")
   if export == nil then export = true
   else export = export[#export] -- get_var returns a table so get the last element
   end
   local countFunc = "get_" .. root .. "_count"
   local getFunc = "get_" .. root .. "_text"
   local lengthFunc = "get_" .. root .. "_length"
   local fileFunc = "get_" .. root .. "_file_name"
   local macroName = name:gsub ("(%w)(%u%l)", "%1_%2"):gsub ("(%l)(%u)", "%1_%2"):upper ()
   local macroHeader = macroName .. "_DOT_H"
   local macroExport = macroName .. "_EXPORT"
   local macroLink = macroName .. "_LINK_SYMBOL"
   if not export then macroLink = "" end
   local target = name .. ".h"
   if file_newer (files, target) then
      fout = io.open (target, "w")
      if fout then
         fout:write ("// WARNING: Auto Generated File. DO NOT EDIT.\n\n")
         fout:write ("#ifndef " .. macroHeader .. "\n")
         fout:write ("#define " .. macroHeader .. "\n\n")
         if export then
            fout:write ("#ifdef _WIN32\n")
            fout:write ("#   ifdef " .. macroExport .. "\n")
            fout:write ("#      define " .. macroLink .. " __declspec (dllexport)\n")
            fout:write ("#   else\n")
            fout:write ("#      define " .. macroLink .. " __declspec (dllimport)\n")
            fout:write ("#   endif\n")
            fout:write ("#else\n")
            fout:write ("#   define " .. macroLink .. "\n")
            fout:write ("#endif\n\n")
         end
         if useNs then
            fout:write ("namespace " .. ns .. " {\n\n")
         end
         if macroLink ~= "" then macroLink = macroLink .. " " end
         fout:write (macroLink .. "int\n")
         fout:write (countFunc .. " ();\n\n")
         fout:write (macroLink .. "const char*\n")
         fout:write (getFunc .. " (const int Which);\n\n")
         fout:write (macroLink .. "int\n")
         fout:write (lengthFunc .. " (const int Which);\n\n")
         fout:write (macroLink .. "const char*\n")
         fout:write (fileFunc .. " (const int Which);\n\n")
         if useNs then
            fout:write ("};\n\n")
         end
         fout:write ("#endif // " .. macroHeader .. "\n")
         io.close (fout)
      end
   end
   add_files {target}
   target = name .. ".cpp"
   if file_newer (files, target) then
      local fout = io.open (target, "w")
      if fout then
         local strLength = {}
         local scope = ""
         if useNs then scope = ns .. "::" end
         fout:write ("// WARNING: Auto Generated File. DO NOT EDIT.\n\n")
         if export then
            fout:write ("#define " .. macroExport .. "\n")
         end
         fout:write ("#include <" .. name .. ".h>\n\n")
         fout:write ("namespace {\n\n")
         for index, inFile in ipairs (files) do
            local count = 0
            fout:write ("// " .. inFile .. "\n")
            fout:write ("static const char text" .. index .. "[] = {\n")
            local instr = nil
            local fin = io.open (inFile, "r")
            if fin then
               instr = fin:read ("*all")
               io.close (fin)
            else error ("Unable to open file: " .. inFile .. " for embedding.")
            end
            if instr then
               local length = instr:len ()
               strLength[index] = length
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
            else strLength[index] = 0;
            end
            fout:write ("  0\n};\n\n")
         end
         fout:write ("};\n\n\n")
         fout:write ("int\n")
         fout:write (scope .. countFunc .. " () { return " .. tostring (#files) ..
            "; }\n\n\n")
         fout:write ("const char *\n")
         fout:write (scope .. getFunc .. " (const int Which) {\n\n")
         fout:write ("   switch (Which) {\n")
         for index, inFile in ipairs (files) do
            fout:write ("      case " .. tostring (index - 1) .. ": return text" ..
               tostring (index) .. "; break; // " .. inFile .. "\n")
         end
         fout:write ("      default: return 0;\n")
         fout:write ("   }\n\n   return 0;\n}\n\n\n")
         fout:write ("int\n")
         fout:write (scope .. lengthFunc .. " (const int Which) {\n\n")
         fout:write ("   switch (Which) {\n")
         for index, inFile in ipairs (files) do
            fout:write ("      case " .. tostring (index - 1) .. ": return " ..
               tostring (strLength[index]) .. "; break; // " .. inFile .. "\n")
         end
         fout:write ("      default: return 0;\n")
         fout:write ("   }\n\n   return 0;\n}\n\n\n")
         fout:write ("const char *\n")
         fout:write (scope .. fileFunc .. " (const int Which) {\n\n")
         fout:write ("   switch (Which) {\n")
         for index, inFile in ipairs (files) do
            fout:write ("      case " .. tostring (index - 1) .. ': return "' ..
               inFile .. '"; break;\n')
         end
         fout:write ("      default: return 0;\n")
         fout:write ("   }\n\n   return 0;\n}\n\n\n")
         io.close (fout)
      else error ("Unable to create file: " .. target)
      end
   end
   add_files {target}
end

function test (files)
   main (files)
end

function clean (files)
end

function clobber (files)
end
