require "lmk"
require "lmkutil"

local startTime = os.time ()

local function print_usage ()
   print ("")
   print ("LMK options:")
   print ("   -u <path/lmk file>")
   print ("   -b <path/lmk file>")
   print ("   -m <debug, opt, bc>")
   print ("   -f <function name>")
   print ("   -r <on/off>")
   print ("   -v <on/off>")
end

local argList = lmkutil.process_args (arg)
local result, msg = true, nil
if argList then
   local doBuild = true
   for ix = 1, #argList do
      local opt = argList[ix].opt
      local values = argList[ix].values
      if opt == "-u" then
         doBuild = false
         if not values then result, msg = lmk.update ()
         else
            for jy = 1, #values do
               result, msg = lmk.update (values[jy])
               if not result then break end
            end
         end
      elseif opt == "-s" then
         if values then
            lmk.set_system (values[1])
         else
         end
      elseif opt == "-b" then
         doBuild = false
         if not values then result, msg = lmk.build ()
         else
            for jy = 1, #values do
               result, msg = lmk.build (values[jy])
               if not result then break end
            end
         end
      elseif opt == "-m" then
         if not values then lmk.set_build_mode ("debug")
         else
            if #values > 1 then
               print ("Warning: -m only take one parameter. " ..
                  "Ignoring other parameters: ")
               for jy = 2, #values do print ("   " .. values[jy]) end
            end
            lmk.set_build_mode (values[1])
         end
      elseif opt == "-p" then
         doBuild = false
         if not values then result, msg = lmk.init ()
         else
            for jy = 1, #values do
               result, msg = lmk.init (values[jy])
               if not result then break end
            end
         end
      elseif opt == "-f" then
         if not values then lmk.set_process_func_name ("main")
         else
            if #values > 1 then
               print ("Warning: -f only take one parameter. " ..
                  "Ignoring other parameters: ")
               for jy = 2, #values do print ("   " .. values[jy]) end
            end
            lmk.set_process_func_name (values[1])
         end
      elseif opt == "-r" then
         if not values then lmk.set_recurse (true)
         else
            local value = values[1]:lower ()
            if (value == "true") or (value == "on") or (value == "1") then
               lmk.set_recurse (true)
            else lmk.set_recurse (false)
            end
         end
      elseif opt == "-v" then
         if not values then lmk.set_verbose (true)
         else
            local value = values[1]:lower ()
            if (value == "true") or (value == "on") or (value == "1") then
               lmk.set_verbose (true)
            else lmk.set_verbose (false)
            end
         end
      elseif opt == "-h" then print_usage (); os.exit ()
      else
         result = false
         msg = "Unknown opt: " .. opt
         print_usage ()
      end
      if not result then break end
   end
   if result and doBuild then lmk.build () end
else result, msg = lmk.build ()
end

if not result then
   print ("Error: " .. (msg and msg or "Unknown Error"))
end
local deltaTime = os.time () - startTime
local hours = math.floor (deltaTime / 3600)
local min = math.floor ((deltaTime - (hours * 3600)) / 60)
local sec = math.floor (deltaTime - ((min * 60) + (hours * 3600)))
print ("Execution time: " ..
    ((hours < 10) and "0"  or "") .. tostring (hours) .. ":" ..
    ((min < 10) and "0"  or "") .. tostring (min) .. ":" ..
    ((sec < 10) and "0"  or "") .. tostring (sec))
