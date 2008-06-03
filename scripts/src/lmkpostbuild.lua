
local print = print

module (...)

function main ()
   print ("")
   print ("Build completed successfully")
end

function test (files)
   print ("")
   print ("Unit tests completed successfully")
end

function clean (files)
   print ("")
   print ("Clean completed successfully")
end

function clobber (files)
   print ("")
   print ("Clobber completed successfully")
end

function distclean (files)
   print ("")
   print ("Distclean completed successfully")
end

