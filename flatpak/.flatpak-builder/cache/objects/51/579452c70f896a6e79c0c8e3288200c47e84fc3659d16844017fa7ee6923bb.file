#include "_gen/tp-svc-channel-dispatch-operation.h"

static const DBusGObjectInfo _tp_svc_channel_dispatch_operation_object_info;

struct _TpSvcChannelDispatchOperationClass {
    GTypeInterface parent_class;
    tp_svc_channel_dispatch_operation_handle_with_impl handle_with_cb;
    tp_svc_channel_dispatch_operation_claim_impl claim_cb;
    tp_svc_channel_dispatch_operation_handle_with_time_impl handle_with_time_cb;
};

enum {
    SIGNAL_CHANNEL_DISPATCH_OPERATION_ChannelLost,
    SIGNAL_CHANNEL_DISPATCH_OPERATION_Finished,
    N_CHANNEL_DISPATCH_OPERATION_SIGNALS
};
static guint channel_dispatch_operation_signals[N_CHANNEL_DISPATCH_OPERATION_SIGNALS] = {0};

static void tp_svc_channel_dispatch_operation_base_init (gpointer klass);

GType
tp_svc_channel_dispatch_operation_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelDispatchOperationClass),
        tp_svc_channel_dispatch_operation_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelDispatchOperation", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_dispatch_operation_handle_with (TpSvcChannelDispatchOperation *self,
    const gchar *in_Handler,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatch_operation_handle_with_impl impl = (TP_SVC_CHANNEL_DISPATCH_OPERATION_GET_CLASS (self)->handle_with_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handler,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatch_operation_implement_handle_with (TpSvcChannelDispatchOperationClass *klass, tp_svc_channel_dispatch_operation_handle_with_impl impl)
{
  klass->handle_with_cb = impl;
}

static void
tp_svc_channel_dispatch_operation_claim (TpSvcChannelDispatchOperation *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatch_operation_claim_impl impl = (TP_SVC_CHANNEL_DISPATCH_OPERATION_GET_CLASS (self)->claim_cb);

  if (impl != NULL)
    {
      (impl) (self,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatch_operation_implement_claim (TpSvcChannelDispatchOperationClass *klass, tp_svc_channel_dispatch_operation_claim_impl impl)
{
  klass->claim_cb = impl;
}

static void
tp_svc_channel_dispatch_operation_handle_with_time (TpSvcChannelDispatchOperation *self,
    const gchar *in_Handler,
    gint64 in_UserActionTime,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_dispatch_operation_handle_with_time_impl impl = (TP_SVC_CHANNEL_DISPATCH_OPERATION_GET_CLASS (self)->handle_with_time_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handler,
        in_UserActionTime,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_channel_dispatch_operation_implement_handle_with_time (TpSvcChannelDispatchOperationClass *klass, tp_svc_channel_dispatch_operation_handle_with_time_impl impl)
{
  klass->handle_with_time_cb = impl;
}

void
tp_svc_channel_dispatch_operation_emit_channel_lost (gpointer instance,
    const gchar *arg_Channel,
    const gchar *arg_Error,
    const gchar *arg_Message)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_DISPATCH_OPERATION));
  g_signal_emit (instance,
      channel_dispatch_operation_signals[SIGNAL_CHANNEL_DISPATCH_OPERATION_ChannelLost],
      0,
      arg_Channel,
      arg_Error,
      arg_Message);
}

void
tp_svc_channel_dispatch_operation_emit_finished (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_DISPATCH_OPERATION));
  g_signal_emit (instance,
      channel_dispatch_operation_signals[SIGNAL_CHANNEL_DISPATCH_OPERATION_Finished],
      0);
}

static inline void
tp_svc_channel_dispatch_operation_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "o", 0, NULL, NULL }, /* Connection */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "o", 0, NULL, NULL }, /* Account */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(oa{sv})", 0, NULL, NULL }, /* Channels */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* PossibleHandlers */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_dispatch_operation_get_type (),
      &_tp_svc_channel_dispatch_operation_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.ChannelDispatchOperation");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("Connection");
  properties[1].type = DBUS_TYPE_G_OBJECT_PATH;
  properties[2].name = g_quark_from_static_string ("Account");
  properties[2].type = DBUS_TYPE_G_OBJECT_PATH;
  properties[3].name = g_quark_from_static_string ("Channels");
  properties[3].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID))));
  properties[4].name = g_quark_from_static_string ("PossibleHandlers");
  properties[4].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_DISPATCH_OPERATION, &interface);

  channel_dispatch_operation_signals[SIGNAL_CHANNEL_DISPATCH_OPERATION_ChannelLost] =
  g_signal_new ("channel-lost",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_STRING);

  channel_dispatch_operation_signals[SIGNAL_CHANNEL_DISPATCH_OPERATION_Finished] =
  g_signal_new ("finished",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

}
static void
tp_svc_channel_dispatch_operation_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_dispatch_operation_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_dispatch_operation_methods[] = {
  { (GCallback) tp_svc_channel_dispatch_operation_handle_with, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_dispatch_operation_claim, g_cclosure_marshal_generic, 77 },
  { (GCallback) tp_svc_channel_dispatch_operation_handle_with_time, g_cclosure_marshal_generic, 137 },
};

static const DBusGObjectInfo _tp_svc_channel_dispatch_operation_object_info = {
  0,
  _tp_svc_channel_dispatch_operation_methods,
  3,
"org.freedesktop.Telepathy.ChannelDispatchOperation\0HandleWith\0A\0Handler\0I\0s\0\0org.freedesktop.Telepathy.ChannelDispatchOperation\0Claim\0A\0\0org.freedesktop.Telepathy.ChannelDispatchOperation\0HandleWithTime\0A\0Handler\0I\0s\0UserActionTime\0I\0x\0\0\0",
"org.freedesktop.Telepathy.ChannelDispatchOperation\0ChannelLost\0org.freedesktop.Telepathy.ChannelDispatchOperation\0Finished\0\0",
"\0\0",
};


