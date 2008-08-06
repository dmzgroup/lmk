local header = [[
#ifndef $(DEF_TAG)
#define $(DEF_TAG)

$(EVENT_INCLUDES)$(INPUT_INCLUDES)$(OBJECT_INCLUDES)#include <dmzRuntimeLog.h>
$(MESSAGE_INCLUDES)#include <dmzRuntimePlugin.h>$(SYNC_INCLUDES)

namespace dmz {

   class $(NAME) :
         public Plugin$(SYNC_PUBLIC)$(MESSAGE_PUBLIC)$(INPUT_PUBLIC)$(OBJECT_PUBLIC)$(EVENT_PUBLIC) {

      public:
         $(NAME) (const PluginInfo &Info, Config &local);
         ~$(NAME) ();

         // Plugin Interface
         virtual void update_plugin_state (
            const PluginStateEnum State,
            const UInt32 Level);

         virtual void discover_plugin (
            const PluginDiscoverEnum Mode,
            const Plugin *PluginPtr);
$(SYNC_INTERFACE)$(MESSAGE_INTERFACE)$(INPUT_INTERFACE)$(OBJECT_INTERFACE)$(EVENT_INTERFACE)
      protected:
         void _init (Config &local);

         Log _log;

      private:
         $(NAME) ();
         $(NAME) (const $(NAME) &);
         $(NAME) &operator= (const $(NAME) &);

   };
};

#endif // $(DEF_TAG)
]]

local cpp = [[
#include "$(HEADER_NAME)"
#include <dmzRuntimePluginFactoryLinkSymbol.h>
#include <dmzRuntimePluginInfo.h>

dmz::$(NAME)::$(NAME) (const PluginInfo &Info, Config &local) :
      Plugin (Info)$(SYNC_CONSTRUCTOR)$(MESSAGE_CONSTRUCTOR)$(INPUT_CONSTRUCTOR)$(OBJECT_CONSTRUCTOR)$(EVENT_CONSTRUCTOR),
      _log (Info) {

   _init (local);
}


dmz::$(NAME)::~$(NAME) () {

}


// Plugin Interface
void
dmz::$(NAME)::update_plugin_state (
      const PluginStateEnum State,
      const UInt32 Level) {

   if (State == PluginStateInit) {

   }
   else if (State == PluginStateStart) {

   }
   else if (State == PluginStateStop) {

   }
   else if (State == PluginStateShutdown) {

   }
}


void
dmz::$(NAME)::discover_plugin (
      const PluginDiscoverEnum Mode,
      const Plugin *PluginPtr) {

   if (Mode == PluginDiscoverAdd) {

   }
   else if (Mode == PluginDiscoverRemove) {

   }
}
$(SYNC_IMPL)$(MESSAGE_IMPL)$(INPUT_IMPL)$(OBJECT_IMPL)$(EVENT_IMPL)

void
dmz::$(NAME)::_init (Config &local) {

}


extern "C" {

DMZ_PLUGIN_FACTORY_LINK_SYMBOL dmz::Plugin *
create_dmz$(NAME) (
      const dmz::PluginInfo &Info,
      dmz::Config &local,
      dmz::Config &global) {

   return new dmz::$(NAME) (Info, local);
}

};
]]

local lmk = [[
lmk.set_name "dmz$(NAME)"
lmk.set_type "plugin"
lmk.add_files {"$(CPP_NAME)",}
lmk.add_libs {
$(LIBS)   "dmzKernel",
}$(PREQS)
]]

local tsh = [[

         // TimeSlice Interface
         virtual void update_time_slice (const Float64 TimeDelta);
]]

local tscpp = [[


// TimeSlice Interface
void
dmz::$(NAME)::update_time_slice (const Float64 TimeDelta) {


}
]]

local msgh = [[

         // Message Observer Interface
         virtual void receive_message (
            const MessageType &Msg,
            const UInt32 MessageSendHandle,
            const Handle TargetObserverHandle,
            const Data *InData,
            Data *outData);
]]

local msgcpp = [[


// Message Observer Interface
void
dmz::$(NAME)::receive_message (
      const MessageType &Msg,
      const UInt32 MessageSendHandle,
      const Handle TargetObserverHandle,
      const Data *InData,
      Data *outData) {

}
]]

local inph = [[

         // Input Observer Interface
         virtual void update_channel_state (const Handle Channel, const Boolean State);

         virtual void receive_axis_event (
            const Handle Channel,
            const InputEventAxis &Value);

         virtual void receive_button_event (
            const Handle Channel,
            const InputEventButton &Value);

         virtual void receive_switch_event (
            const Handle Channel,
            const InputEventSwitch &Value);

         virtual void receive_key_event (
            const Handle Channel,
            const InputEventKey &Value);

         virtual void receive_mouse_event (
            const Handle Channel,
            const InputEventMouse &Value);

         virtual void receive_data_event (
            const Handle Channel,
            const Handle Source,
            const Data &Value);
]]

local inpcpp = [[


// Input Observer Interface
void
dmz::$(NAME)::update_channel_state (const Handle Channel, const Boolean State) {

}


void
dmz::$(NAME)::receive_axis_event (
      const Handle Channel,
      const InputEventAxis &Value) {

}


void
dmz::$(NAME)::receive_button_event (
      const Handle Channel,
      const InputEventButton &Value) {

}


void
dmz::$(NAME)::receive_switch_event (
      const Handle Channel,
      const InputEventSwitch &Value) {

}


void
dmz::$(NAME)::receive_key_event (
      const Handle Channel,
      const InputEventKey &Value) {

}


void
dmz::$(NAME)::receive_mouse_event (
      const Handle Channel,
      const InputEventMouse &Value) {

}


void
dmz::$(NAME)::receive_data_event (
      const Handle Channel,
      const Handle Source,
      const Data &Value) {

}
]]

local objh = [[

         // Object Observer Interface
         virtual void create_object (
            const UUID &Identity,
            const Handle ObjectHandle,
            const ObjectType &Type,
            const ObjectLocalityEnum Locality);

         virtual void destroy_object (const UUID &Identity, const Handle ObjectHandle);

         virtual void update_object_uuid (
            const Handle ObjectHandle,
            const UUID &Identity,
            const UUID &PrevIdentity);

         virtual void remove_object_attribute (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Mask &AttrMask);

         virtual void update_object_locality (
            const UUID &Identity,
            const Handle ObjectHandle,
            const ObjectLocalityEnum Locality,
            const ObjectLocalityEnum PrevLocality);

         virtual void link_objects (
            const Handle LinkHandle,
            const Handle AttributeHandle,
            const UUID &SuperIdentity,
            const Handle SuperHandle,
            const UUID &SubIdentity,
            const Handle SubHandle);

         virtual void unlink_objects (
            const Handle LinkHandle,
            const Handle AttributeHandle,
            const UUID &SuperIdentity,
            const Handle SuperHandle,
            const UUID &SubIdentity,
            const Handle SubHandle);

         virtual void update_link_attribute_object (
            const Handle LinkHandle,
            const Handle AttributeHandle,
            const UUID &SuperIdentity,
            const Handle SuperHandle,
            const UUID &SubIdentity,
            const Handle SubHandle,
            const UUID &AttributeIdentity,
            const Handle AttributeObjectHandle,
            const UUID &PrevAttributeIdentity,
            const Handle PrevAttributeObjectHandle);

         virtual void update_object_type (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const ObjectType &Value,
            const ObjectType *PreviousValue);

         virtual void update_object_state (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Mask &Value,
            const Mask *PreviousValue);

         virtual void update_object_flag (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Boolean Value,
            const Boolean *PreviousValue);

         virtual void update_object_time_stamp (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Float64 &Value,
            const Float64 *PreviousValue);

         virtual void update_object_position (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Vector &Value,
            const Vector *PreviousValue);

         virtual void update_object_orientation (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Matrix &Value,
            const Matrix *PreviousValue);

         virtual void update_object_velocity (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Vector &Value,
            const Vector *PreviousValue);

         virtual void update_object_acceleration (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Vector &Value,
            const Vector *PreviousValue);

         virtual void update_object_scale (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Vector &Value,
            const Vector *PreviousValue);

         virtual void update_object_vector (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Vector &Value,
            const Vector *PreviousValue);

         virtual void update_object_scalar (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Float64 Value,
            const Float64 *PreviousValue);

         virtual void update_object_text (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const String &Value,
            const String *PreviousValue);

         virtual void update_object_data (
            const UUID &Identity,
            const Handle ObjectHandle,
            const Handle AttributeHandle,
            const Data &Value,
            const Data *PreviousValue);
]]

local objcpp = [[


// Object Observer Interface
void
dmz::$(NAME)::create_object (
      const UUID &Identity,
      const Handle ObjectHandle,
      const ObjectType &Type,
      const ObjectLocalityEnum Locality) {

}


void
dmz::$(NAME)::destroy_object (
      const UUID &Identity,
      const Handle ObjectHandle) {

}


void
dmz::$(NAME)::update_object_uuid (
      const Handle ObjectHandle,
      const UUID &Identity,
      const UUID &PrevIdentity) {

}


void
dmz::$(NAME)::remove_object_attribute (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Mask &AttrMask) {

}


void
dmz::$(NAME)::update_object_locality (
      const UUID &Identity,
      const Handle ObjectHandle,
      const ObjectLocalityEnum Locality,
      const ObjectLocalityEnum PrevLocality) {

}


void
dmz::$(NAME)::link_objects (
      const Handle LinkHandle,
      const Handle AttributeHandle,
      const UUID &SuperIdentity,
      const Handle SuperHandle,
      const UUID &SubIdentity,
      const Handle SubHandle) {

}


void
dmz::$(NAME)::unlink_objects (
      const Handle LinkHandle,
      const Handle AttributeHandle,
      const UUID &SuperIdentity,
      const Handle SuperHandle,
      const UUID &SubIdentity,
      const Handle SubHandle) {

}


void
dmz::$(NAME)::update_link_attribute_object (
      const Handle LinkHandle,
      const Handle AttributeHandle,
      const UUID &SuperIdentity,
      const Handle SuperHandle,
      const UUID &SubIdentity,
      const Handle SubHandle,
      const UUID &AttributeIdentity,
      const Handle AttributeObjectHandle,
      const UUID &PrevAttributeIdentity,
      const Handle PrevAttributeObjectHandle) {


}


void
dmz::$(NAME)::update_object_type (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const ObjectType &Value,
      const ObjectType *PreviousValue) {

}


void
dmz::$(NAME)::update_object_state (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Mask &Value,
      const Mask *PreviousValue) {

}


void
dmz::$(NAME)::update_object_flag (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Boolean Value,
      const Boolean *PreviousValue) {

}


void
dmz::$(NAME)::update_object_time_stamp (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Float64 &Value,
      const Float64 *PreviousValue) {

}


void
dmz::$(NAME)::update_object_position (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Vector &Value,
      const Vector *PreviousValue) {

}


void
dmz::$(NAME)::update_object_orientation (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Matrix &Value,
      const Matrix *PreviousValue) {

}


void
dmz::$(NAME)::update_object_velocity (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Vector &Value,
      const Vector *PreviousValue) {

}


void
dmz::$(NAME)::update_object_acceleration (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Vector &Value,
      const Vector *PreviousValue) {

}


void
dmz::$(NAME)::update_object_scale (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Vector &Value,
      const Vector *PreviousValue) {

}


void
dmz::$(NAME)::update_object_vector (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Vector &Value,
      const Vector *PreviousValue) {

}


void
dmz::$(NAME)::update_object_scalar (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Float64 Value,
      const Float64 *PreviousValue) {

}


void
dmz::$(NAME)::update_object_text (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const String &Value,
      const String *PreviousValue) {

}


void
dmz::$(NAME)::update_object_data (
      const UUID &Identity,
      const Handle ObjectHandle,
      const Handle AttributeHandle,
      const Data &Value,
      const Data *PreviousValue) {

}
]]

local evnh = [[

         // Event Observer Interface
         virtual void start_event (
            const Handle EventHandle,
            const EventType &Type,
            const EventLocalityEnum Locality);

         virtual void end_event (
            const Handle EventHandle,
            const EventType &Type);
]]

local evncpp = [[


// Event Observer Interface
void
dmz::$(NAME)::start_event (
      const Handle EventHandle,
      const EventType &Type,
      const EventLocalityEnum Locality) {

}


void
dmz::$(NAME)::end_event (
      const Handle EventHandle,
      const EventType &Type) {

}
]]

local name = arg[1]
local list = nil
for ix = 2, #arg do
   if not list then list = {} end
   if arg[ix]:sub (1, 1) == "-" then
      list[#list + 1] = { opt = arg[ix] }
   elseif list[#list] then
      if not list[#list].values then list[#list].values = {} end
      list[#list].values[#(list[#list].values) + 1] = arg[ix]
   else
   end
end
if name then
   local headerName = "dmz" .. name .. ".h"
   local cppName = "dmz" .. name .. ".cpp"
   local lmkName = "dmz" .. name .. ".lmk"
   local defTag = headerName:gsub ("%.", "Dot_")
      :gsub ("(%w)(%u%l)", "%1_%2"):gsub ("(%l)(%u)", "%1_%2"):upper ()
print (lmkName .. " " .. headerName .. " " .. cppName .. " "  .. defTag)
   local vars = {
      NAME = name,
      HEADER_NAME = headerName,
      CPP_NAME = cppName,
      LIBS = "",
      PREQS = "",
      DEF_TAG = defTag,
      SYNC_INCLUDES = "",
      SYNC_PUBLIC = "",
      SYNC_CONSTRUCTOR = "",
      SYNC_INTERFACE = "",
      SYNC_IMPL = "",
      MESSAGE_INCLUDES = "",
      MESSAGE_PUBLIC = "",
      MESSAGE_CONSTRUCTOR = "",
      MESSAGE_INTERFACE = "",
      MESSAGE_IMPL = "",
      INPUT_PREQS = "",
      INPUT_INCLUDES = "",
      INPUT_PUBLIC = "",
      INPUT_CONSTRUCTOR = "",
      INPUT_INTERFACE = "",
      INPUT_IMPL = "",
      OBJECT_PREQS = "",
      OBJECT_INCLUDES = "",
      OBJECT_PUBLIC = "",
      OBJECT_CONSTRUCTOR = "",
      OBJECT_INTERFACE = "",
      OBJECT_IMPL = "",
      EVENT_PREQS = "",
      EVENT_INCLUDES = "",
      EVENT_PUBLIC = "",
      EVENT_CONSTRUCTOR = "",
      EVENT_INTERFACE = "",
      EVENT_IMPL = "",
   }
   if list then
      for ix = 1, #list do
         if list[ix].opt== "-t" then
            vars.SYNC_INCLUDES = "\n#include <dmzRuntimeTimeSlice.h>"
            vars.SYNC_PUBLIC = ",\n         public TimeSlice"
            vars.SYNC_CONSTRUCTOR = ',\n      TimeSlice (Info)'
            vars.SYNC_INTERFACE = tsh:gsub ("%$%(([_%w]+)%)", vars)
            vars.SYNC_IMPL = tscpp:gsub ("%$%(([_%w]+)%)", vars)
         elseif list[ix].opt== "-o" then
            vars.LIBS = vars.LIBS .. '   "dmzObjectUtil",\n'
            vars.OBJECT_PREQS = '"dmzObjectFramework",'
            vars.OBJECT_INCLUDES = "#include <dmzObjectObserverUtil.h>\n"
            vars.OBJECT_PUBLIC = ",\n         public ObjectObserverUtil"
            vars.OBJECT_CONSTRUCTOR = ',\n      ObjectObserverUtil (Info, local)'
            vars.OBJECT_INTERFACE = objh:gsub ("%$%(([_%w]+)%)", vars)
            vars.OBJECT_IMPL = objcpp:gsub ("%$%(([_%w]+)%)", vars)
         elseif list[ix].opt == "-i" then
            vars.LIBS = vars.LIBS .. '   "dmzInputEvents",\n   "dmzInputUtil",\n'
            vars.INPUT_PREQS = '"dmzInputFramework",'
            vars.INPUT_INCLUDES = "#include <dmzInputObserverUtil.h>\n"
            vars.INPUT_PUBLIC = ",\n         public InputObserverUtil"
            vars.INPUT_CONSTRUCTOR = ',\n      InputObserverUtil (Info, local)'
            vars.INPUT_INTERFACE = inph:gsub ("%$%(([_%w]+)%)", vars)
            vars.INPUT_IMPL = inpcpp:gsub ("%$%(([_%w]+)%)", vars)
         elseif list[ix].opt == "-m" then
            vars.MESSAGE_INCLUDES = "#include <dmzRuntimeMessaging.h>\n"
            vars.MESSAGE_PUBLIC = ",\n         public MessageObserver"
            vars.MESSAGE_CONSTRUCTOR = ",\n      MessageObserver (Info)"
            vars.MESSAGE_INTERFACE = msgh:gsub ("%$%(([_%w]+)%)", vars)
            vars.MESSAGE_IMPL = msgcpp:gsub ("%$%(([_%w]+)%)", vars)
         elseif list[ix].opt == "-e" then
            vars.LIBS = vars.LIBS .. '   "dmzEventUtil",\n'
            vars.EVENT_PREQS = '"dmzEventFramework",'
            vars.EVENT_INCLUDES = "#include <dmzEventObserverUtil.h>\n"
            vars.EVENT_PUBLIC = ",\n         public EventObserverUtil"
            vars.EVENT_CONSTRUCTOR = ',\n      EventObserverUtil (Info, local)'
            vars.EVENT_INTERFACE = evnh:gsub ("%$%(([_%w]+)%)", vars)
            vars.EVENT_IMPL = evncpp:gsub ("%$%(([_%w]+)%)", vars)
         end
      end
   end
   vars.PREQS_LIST = vars.OBJECT_PREQS
   if string.len (vars.INPUT_PREQS) > 0 then
      if string.len (vars.PREQS_LIST) > 0 then
         vars.PREQS_LIST = vars.PREQS_LIST .. " " .. vars.INPUT_PREQS
      else vars.PREQS_LIST = vars.INPUT_PREQS
      end
   end
   if string.len (vars.EVENT_PREQS) > 0 then
      if string.len (vars.PREQS_LIST) > 0 then
         vars.PREQS_LIST = vars.PREQS_LIST .. " " .. vars.EVENT_PREQS
      else vars.PREQS_LIST = vars.EVENT_PREQS
      end
   end
   if string.len (vars.PREQS_LIST) > 0 then
      vars.PREQS = "\nlmk.add_preqs {" .. vars.PREQS_LIST .. "}"
   end
   local hfile = header:gsub ("%$%(([_%w]+)%)", vars)
   local cppfile = cpp:gsub ("%$%(([_%w]+)%)", vars)
   local lmkfile = lmk:gsub ("%$%(([_%w]+)%)", vars)
print ("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
   print (hfile)
print ("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
   print (cppfile)
print ("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
   print (lmkfile)
print ("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
   local fout = io.open (headerName, "w")
   if fout then fout:write (hfile); io.close (fout) end
   fout = io.open (cppName, "w")
   if fout then fout:write (cppfile); io.close (fout) end
   fout = io.open (lmkName, "w")
   if fout then fout:write (lmkfile); io.close (fout) end
end
