require "lmkbase"

local result, msg = true, ""
print ("System: " .. lmkbase.system ())
if not lmkbase.is_valid ("./test_dir") then
   result, msg = lmkbase.mkdir ("./test_dir/")
   if not result then print ("Failed creating dir: " .. msg) end
else print ("./test_dir already exists")
end
print ("./test_dir is_dir: " .. tostring (lmkbase.is_dir ("./test_dir")))
result, msg = lmkbase.file_newer ("./file1.txt", "./file2.txt") 
if result == true then print ("file 1 is newer")
elseif result == false then print ("file 2 is newer") 
else print ("File compare fails: " .. msg)
end
print ("./file1 is_dir: " .. tostring (lmkbase.is_dir ("./file1.txt")))
result, msg = lmkbase.rm ("./test_dir/")
if not result then print ("Failed removing dir: " .. msg) end
print (lmkbase.pwd ())
local list, ferror = lmkbase.files (".")
if list then print ("file list: " .. table.concat (list, " "))
else print ("no file list returned:" .. ferror);
end
local dlist, derror = "", ""
if lmkbase.system () == "win32" then
   dlist, derror = lmkbase.directories ("c:\\")
else
   dlist, derror = lmkbase.directories ("/")
end
if dlist then print ("dir list: '" .. table.concat (dlist, "' '") .. "'")
else print ("no dir list returned: " .. derror);
end
if lmkbase.cd ("..") then print ("cd to: " .. lmkbase.pwd ());
else print ("Error, cd failed");
end

