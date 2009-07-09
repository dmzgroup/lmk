local lf = print
local print = lmkbuild.print_success

module (...)

function main ()
   lf ("")
   print ("Build completed successfully")
end

function test (files)
   lf ("")
   print ("Unit tests completed successfully")
end

function clean (files)
   lf ("")
   print ("Clean completed successfully")
end

function clobber (files)
   lf ("")
   print ("Clobber completed successfully")
end

function distclean (files)
   lf ("")
   print ("Distclean completed successfully")
end

