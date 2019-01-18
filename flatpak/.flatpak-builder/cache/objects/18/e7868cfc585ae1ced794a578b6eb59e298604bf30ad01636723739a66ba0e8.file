#include "_gen/tp-svc-channel-dispatcher.h"

static const DBusGObjectInfo _tp_svc_channel_dispatcher_object_info;

struct _TpSvcChannelDispatcherClass {
    GTypeInterface parent_class;
    tp_svc_channel_dispatcher_create_channel_impl create_channel_cb;
    tp_svc_channel_dispatcher_ensure_channel_impl ensure_channel_cb;
    tp_svc_channel_dispatcher_create_channel_with_hints_impl create_channel_with_hints_cb;
    tp_svc_channel_dispatcher_ensure_channel_with_hints_impl ensure_channel_with_hints_cb;
    tp_svc_channel_dispatcher_delegate_channels_impl delegate_channels_cb;
    tp_svc_channel_dispatcher_present_channel_impl present_channel_cb;
};

static void tp_svc_channel_dispatcher_base_init (gpointer klass);

GType
tp_svc_channel_dispatcher_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelDispatcherClass),
        tp_svc_channel_dispatcher_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelDispatcher", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_dispatcher_create_channel (TpSvcChannelDispatcher *self,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatcher_create_channel_impl impl = (TP_SVC_CHANNEL_DISPATCHER_GET_CLASS (self)->create_channel_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Account,
        in_Requested_Properties,
        in_User_Action_Time,
        in_Preferred_Handler,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatcher_implement_create_channel (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_create_channel_impl impl)
{
  klass->create_channel_cb = impl;
}

static void
tp_svc_channel_dispatcher_ensure_channel (TpSvcChannelDispatcher *self,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatcher_ensure_channel_impl impl = (TP_SVC_CHANNEL_DISPATCHER_GET_CLASS (self)->ensure_channel_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Account,
        in_Requested_Properties,
        in_User_Action_Time,
        in_Preferred_Handler,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatcher_implement_ensure_channel (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_ensure_channel_impl impl)
{
  klass->ensure_channel_cb = impl;
}

static void
tp_svc_channel_dispatcher_create_channel_with_hints (TpSvcChannelDispatcher *self,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    GHashTable *in_Hints,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatcher_create_channel_with_hints_impl impl = (TP_SVC_CHANNEL_DISPATCHER_GET_CLASS (self)->create_channel_with_hints_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Account,
        in_Requested_Properties,
        in_User_Action_Time,
        in_Preferred_Handler,
        in_Hints,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatcher_implement_create_channel_with_hints (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_create_channel_with_hints_impl impl)
{
  klass->create_channel_with_hints_cb = impl;
}

static void
tp_svc_channel_dispatcher_ensure_channel_with_hints (TpSvcChannelDispatcher *self,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    GHashTable *in_Hints,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatcher_ensure_channel_with_hints_impl impl = (TP_SVC_CHANNEL_DISPATCHER_GET_CLASS (self)->ensure_channel_with_hints_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Account,
        in_Requested_Properties,
        in_User_Action_Time,
        in_Preferred_Handler,
        in_Hints,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatcher_implement_ensure_channel_with_hints (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_ensure_channel_with_hints_impl impl)
{
  klass->ensure_channel_with_hints_cb = impl;
}

static void
tp_svc_channel_dispatcher_delegate_channels (TpSvcChannelDispatcher *self,
    const GPtrArray *in_Channels,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatcher_delegate_channels_impl impl = (TP_SVC_CHANNEL_DISPATCHER_GET_CLASS (self)->delegate_channels_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Channels,
        in_User_Action_Time,
        in_Preferred_Handler,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatcher_implement_delegate_channels (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_delegate_channels_impl impl)
{
  klass->delegate_channels_cb = impl;
}

static void
tp_svc_channel_dispatcher_present_channel (TpSvcChannelDispatcher *self,
    const gchar *in_Channel,
    gint64 in_User_Action_Time,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatcher_present_channel_impl impl = (TP_SVC_CHANNEL_DISPATCHER_GET_CLASS (self)->present_channel_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Channel,
        in_User_Action_Time,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatcher_implement_present_channel (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_present_channel_impl impl)
{
  klass->present_channel_cb = impl;
}

static inline void
tp_svc_channel_dispatcher_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* SupportsRequestHints */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_dispatcher_get_type (),
      &_tp_svc_channel_dispatcher_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.ChannelDispatcher");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("SupportsRequestHints");
  properties[1].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_DISPATCHER, &interface);

}
static void
tp_svc_channel_dispatcher_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_dispatcher_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_dispatcher_methods[] = {
  { (GCallback) tp_svc_channel_dispatcher_create_channel, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_dispatcher_ensure_channel, g_cclosure_marshal_generic, 161 },
  { (GCallback) tp_svc_channel_dispatcher_create_channel_with_hints, g_cclosure_marshal_generic, 322 },
  { (GCallback) tp_svc_channel_dispatcher_ensure_channel_with_hints, g_cclosure_marshal_generic, 506 },
  { (GCallback) tp_svc_channel_dispatcher_delegate_channels, g_cclosure_marshal_generic, 690 },
  { (GCallback) tp_svc_channel_dispatcher_present_channel, g_cclosure_marshal_generic, 859 },
};

static const DBusGObjectInfo _tp_svc_channel_dispatcher_object_info = {
  0,
  _tp_svc_channel_dispatcher_methods,
  6,
"org.freedesktop.Telepathy.ChannelDispatcher\0CreateChannel\0A\0Account\0I\0o\0Requested_Properties\0I\0a{sv}\0User_Action_Time\0I\0x\0Preferred_Handler\0I\0s\0Request\0O\0F\0N\0o\0\0org.freedesktop.Telepathy.ChannelDispatcher\0EnsureChannel\0A\0Account\0I\0o\0Requested_Properties\0I\0a{sv}\0User_Action_Time\0I\0x\0Preferred_Handler\0I\0s\0Request\0O\0F\0N\0o\0\0org.freedesktop.Telepathy.ChannelDispatcher\0CreateChannelWithHints\0A\0Account\0I\0o\0Requested_Properties\0I\0a{sv}\0User_Action_Time\0I\0x\0Preferred_Handler\0I\0s\0Hints\0I\0a{sv}\0Request\0O\0F\0N\0o\0\0org.freedesktop.Telepathy.ChannelDispatcher\0EnsureChannelWithHints\0A\0Account\0I\0o\0Requested_Properties\0I\0a{sv}\0User_Action_Time\0I\0x\0Preferred_Handler\0I\0s\0Hints\0I\0a{sv}\0Request\0O\0F\0N\0o\0\0org.freedesktop.Telepathy.ChannelDispatcher\0DelegateChannels\0A\0Channels\0I\0ao\0User_Action_Time\0I\0x\0Preferred_Handler\0I\0s\0Delegated\0O\0F\0N\0ao\0Not_Delegated\0O\0F\0N\0a{o(ss)}\0\0org.freedesktop.Telepathy.ChannelDispatcher\0PresentChannel\0A\0Channel\0I\0o\0User_Action_Time\0I\0x\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_dispatcher_interface_messages1_object_info;

struct _TpSvcChannelDispatcherInterfaceMessages1Class {
    GTypeInterface parent_class;
    tp_svc_channel_dispatcher_interface_messages1_send_message_impl send_message_cb;
};

static void tp_svc_channel_dispatcher_interface_messages1_base_init (gpointer klass);

GType
tp_svc_channel_dispatcher_interface_messages1_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelDispatcherInterfaceMessages1Class),
        tp_svc_channel_dispatcher_interface_messages1_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelDispatcherInterfaceMessages1", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_dispatcher_interface_messages1_send_message (TpSvcChannelDispatcherInterfaceMessages1 *self,
    const gchar *in_Account,
    const gchar *in_Target_ID,
    const GPtrArray *in_Message,
    guint in_Flags,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatcher_interface_messages1_send_message_impl impl = (TP_SVC_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1_GET_CLASS (self)->send_message_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Account,
        in_Target_ID,
        in_Message,
        in_Flags,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatcher_interface_messages1_implement_send_message (TpSvcChannelDispatcherInterfaceMessages1Class *klass, tp_svc_channel_dispatcher_interface_messages1_send_message_impl impl)
{
  klass->send_message_cb = impl;
}

static inline void
tp_svc_channel_dispatcher_interface_messages1_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_channel_dispatcher_interface_messages1_get_type (),
      &_tp_svc_channel_dispatcher_interface_messages1_object_info);

}
static void
tp_svc_channel_dispatcher_interface_messages1_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_dispatcher_interface_messages1_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_dispatcher_interface_messages1_methods[] = {
  { (GCallback) tp_svc_channel_dispatcher_interface_messages1_send_message, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_channel_dispatcher_interface_messages1_object_info = {
  0,
  _tp_svc_channel_dispatcher_interface_messages1_methods,
  1,
"org.freedesktop.Telepathy.ChannelDispatcher.Interface.Messages1\0SendMessage\0A\0Account\0I\0o\0Target_ID\0I\0s\0Message\0I\0aa{sv}\0Flags\0I\0u\0Token\0O\0F\0N\0s\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_channel_dispatcher_interface_operation_list_object_info;

struct _TpSvcChannelDispatcherInterfaceOperationListClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_NewDispatchOperation,
    SIGNAL_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_DispatchOperationFinished,
    N_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_SIGNALS
};
static guint channel_dispatcher_interface_operation_list_signals[N_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_SIGNALS] = {0};

static void tp_svc_channel_dispatcher_interface_operation_list_base_init (gpointer klass);

GType
tp_svc_channel_dispatcher_interface_operation_list_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelDispatcherInterfaceOperationListClass),
        tp_svc_channel_dispatcher_interface_operation_list_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelDispatcherInterfaceOperationList", &info, 0);
    }

  return type;
}

void
tp_svc_channel_dispatcher_interface_operation_list_emit_new_dispatch_operation (gpointer instance,
    const gchar *arg_Dispatch_Operation,
    GHashTable *arg_Properties)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST));
  g_signal_emit (instance,
      channel_dispatcher_interface_operation_list_signals[SIGNAL_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_NewDispatchOperation],
      0,
      arg_Dispatch_Operation,
      arg_Properties);
}

void
tp_svc_channel_dispatcher_interface_operation_list_emit_dispatch_operation_finished (gpointer instance,
    const gchar *arg_Dispatch_Operation)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST));
  g_signal_emit (instance,
      channel_dispatcher_interface_operation_list_signals[SIGNAL_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_DispatchOperationFinished],
      0,
      arg_Dispatch_Operation);
}

static inline void
tp_svc_channel_dispatcher_interface_operation_list_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(oa{sv})", 0, NULL, NULL }, /* DispatchOperations */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_dispatcher_interface_operation_list_get_type (),
      &_tp_svc_channel_dispatcher_interface_operation_list_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.ChannelDispatcher.Interface.OperationList");
  properties[0].name = g_quark_from_static_string ("DispatchOperations");
  properties[0].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID))));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST, &interface);

  channel_dispatcher_interface_operation_list_signals[SIGNAL_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_NewDispatchOperation] =
  g_signal_new ("new-dispatch-operation",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

  channel_dispatcher_interface_operation_list_signals[SIGNAL_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_DispatchOperationFinished] =
  g_signal_new ("dispatch-operation-finished",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      DBUS_TYPE_G_OBJECT_PATH);

}
static void
tp_svc_channel_dispatcher_interface_operation_list_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_dispatcher_interface_operation_list_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_dispatcher_interface_operation_list_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_channel_dispatcher_interface_operation_list_object_info = {
  0,
  _tp_svc_channel_dispatcher_interface_operation_list_methods,
  0,
"\0",
"org.freedesktop.Telepathy.ChannelDispatcher.Interface.OperationList\0NewDispatchOperation\0org.freedesktop.Telepathy.ChannelDispatcher.Interface.OperationList\0DispatchOperationFinished\0\0",
"\0\0",
};


