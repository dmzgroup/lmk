require "lmkbase"

local function copy (source, target, header)
   if not lmkbase.is_dir (target) then
      lmkbase.mkdir (target)
   end
   local inp = io.open (source, "rb")
   local out = io.open (target .. "/" .. header, "wb")
   if inp and out then
      local data = inp:read ("*all")
      out:write (data)
      io.close (inp)
      io.close (out)
   end
end

local function process (target, source)
--print (target, source)
   local files = lmkbase.files (source)
   if files then
      for i, f in ipairs (files) do
         if f:find ("^[%w._]*h$") then
--print ("Found: " .. f)
            local header = io.open (source .. "/" .. f)
            if header then
               for line in header:lines () do
                  local realFile = line:match ('#include[%s]*"([%w/._]*)"')
                  if realFile then 
                     if lmkbase.is_valid (source .. "/" .. realFile) then
print (realFile)
                        copy (source .. "/" .. realFile, target, f)
                     else print ("File not valid: " .. source .. "/" .. realFile)
                     end
                  else print ("No match: " .. line)
                  end
               end
               header:close ()
            end
         else copy (source .. "/" .. f, target, f)
         end
      end
   end
   local dirs = lmkbase.directories (source)
   if dirs then
      for i, v in ipairs (dirs) do
         process (target .. "/" .. v, source .. "/" .. v)
      end
   end
end

local target = arg[1]
local start = arg[2]

if start and lmkbase.is_dir (start) then
   local pwd = lmkbase.pwd ()
   lmkbase.cd (start)
   start = lmkbase.pwd ()
   lmkbase.cd (pwd)
else start = nil
end
if not start then start = lmkbase.pwd () end

if lmkbase.is_dir (target) then process (target, start)
else print ("Not a valid target dir: " .. target)
end
