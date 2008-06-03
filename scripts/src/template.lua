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

module (...)

local function process_file (inFile, outVars)
   local instr = nil
   local inPath, fileAndVarName, ext = split (inFile)
   local _, preOutFile, varName = split (fileAndVarName);
   for index, vars in ipairs (outVars[varName]) do
      local outFile = preOutFile:gsub ("-([%w]+)-", vars) .. "." .. ext
--      local outPath = resolve ("$(localTmpDir)" .. outFile)
      local outPath = resolve (inPath .. "/" .. outFile)
      if file_newer (inFile, outPath) then
         if not instr then
            local fin = io.open (inFile, "r")
            if fin then
               instr = fin:read ("*all")
               io.close (fin)
            else error ("Unable to open template input file: " .. inFile);
            end
         end
         local outstr = instr:gsub ("%$%((%w+)%)", vars)
         local fout = io.open (outPath, "w")
         if fout then
            print ("Creating file: " .. outPath)
            local defTag = nil
            if ext == "h" then
               defTag = outFile:gsub ("%.", "Dot_"):
                  gsub ("(%w)(%u%l)", "%1_%2"):gsub ("(%l)(%u)", "%1_%2"):upper ()
               fout:write ("#ifndef " .. defTag .. "\n")
               fout:write ("#define " .. defTag .. "\n")
            end
            fout:write (outstr)
            if ext == "h" then
               fout:write ("#endif /* " .. defTag .. " */\n")
            end
            io.close (fout)
         else error ("Unable to open template output file: " .. outPath);
         end
      end
      add_files ({outPath}, ext)
   end
end

local function clean_file (inFile, outVars)
   local instr = nil
   local inPath, fileAndVarName, ext = split (inFile)
   local _, preOutFile, varName = split (fileAndVarName);
   for index, vars in ipairs (outVars[varName]) do
      local outFile = preOutFile:gsub ("-([%w]+)-", vars) .. "." .. ext
--      local outPath = resolve ("$(localTmpDir)" .. outFile)
      local outPath = resolve (inPath .. "/" .. outFile)
      if is_valid (outPath) then rm (outPath) end
      add_files ({outPath}, ext)
   end
end

function main (files)
   local outVars = get ("templateDefine")
   if outVars then
      for index, inFile in ipairs (files) do
         process_file (inFile, outVars)
      end
   end
end

function test (files)
   main (files)
end

function clean (files)
   local outVars = get ("templateDefine")
   if outVars then
      for index, inFile in ipairs (files) do
         clean_file (inFile, outVars)
      end
   end
end

function clobber (files)
   clean (files)
end
