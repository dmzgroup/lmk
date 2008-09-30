local header = [[
#ifndef $(DEF_TAG)
#define $(DEF_TAG)

#include <dmzRuntimePlugin.h>
#include <dmzRuntimeRTTI.h>
#include <dmzTypesBase.h>
#include <dmzTypesString.h>

namespace dmz {

   //! \cond
   const char $(NAME)InterfaceName[] = "$(NAME)Interface";
   //! \endcond

   class $(NAME) {

      public:
         static $(NAME) *cast (
            const Plugin *PluginPtr,
            const String &PluginName = "");

         String get_$(LOWER_NAME)_name () const;
         Handle get_$(LOWER_NAME)_handle () const;

         // $(NAME) Interface

      protected:
         $(NAME) (const PluginInfo &Info);
         ~$(NAME) ();

      private:
         $(NAME) ();
         $(NAME) (const $(NAME) &);
         $(NAME) &operator= (const $(NAME) &);

         const PluginInfo &__Info;
   };
};


inline dmz::$(NAME) *
dmz::$(NAME)::cast (const Plugin *PluginPtr, const String &PluginName) {

   return ($(NAME) *)lookup_rtti_interface (
      $(NAME)InterfaceName,
      PluginName,
      PluginPtr);
}


inline
dmz::$(NAME)::$(NAME) (const PluginInfo &Info) :
      __Info (Info) {

   store_rtti_interface ($(NAME)InterfaceName, __Info, (void *)this);
}


inline
dmz::$(NAME)::~$(NAME) () {

   remove_rtti_interface ($(NAME)InterfaceName, __Info);
}


inline dmz::String
dmz::$(NAME)::get_$(LOWER_NAME)_name () const { return __Info.get_name (); }


inline dmz::Handle
dmz::$(NAME)::get_$(LOWER_NAME)_handle () const { return __Info.get_handle (); }

#endif // $(DEF_TAG)
]]

local name = arg[1]
if name then
   local headerName = "dmz" .. name .. ".h"
   local lowerName = name:gsub ("(%l)(%u)",  "%1_%2"):lower ()
   local defTag = headerName:gsub ("%.", "Dot_")
      :gsub ("(%w)(%u%l)", "%1_%2"):gsub ("(%l)(%u)", "%1_%2"):upper ()
print (headerName)
   local vars = {
      NAME = name,
      LOWER_NAME = lowerName,
      DEF_TAG = defTag,
   }
   local hfile = header:gsub ("%$%(([_%w]+)%)", vars)
print ("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
   print (hfile)
print ("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
   local fout = io.open (headerName, "w")
   if fout then fout:write (hfile); io.close (fout) end
end
