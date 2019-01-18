#include "_gen/tp-svc-channel-request.h"

static const DBusGObjectInfo _tp_svc_channel_request_object_info;

struct _TpSvcChannelRequestClass {
    GTypeInterface parent_class;
    tp_svc_channel_request_proceed_impl proceed_cb;
    tp_svc_channel_request_cancel_impl cancel_cb;
};

enum {
    SIGNAL_CHANNEL_REQUEST_Failed,
    SIGNAL_CHANNEL_REQUEST_Succeeded,
    SIGNAL_CHANNEL_REQUEST_SucceededWithChannel,
    N_CHANNEL_REQUEST_SIGNALS
};
static guint channel_request_signals[N_CHANNEL_REQUEST_SIGNALS] = {0};

static void tp_svc_channel_request_base_init (gpointer klass);

GType
tp_svc_channel_request_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcChannelRequestClass),
        tp_svc_channel_request_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcChannelRequest", &info, 0);
    }

  return type;
}

static void
tp_svc_channel_request_proceed (TpSvcChannelRequest *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_request_proceed_impl impl = (TP_SVC_CHANNEL_REQUEST_GET_CLASS (self)->proceed_cb);

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
tp_svc_channel_request_implement_proceed (TpSvcChannelRequestClass *klass, tp_svc_channel_request_proceed_impl impl)
{
  klass->proceed_cb = impl;
}

static void
tp_svc_channel_request_cancel (TpSvcChannelRequest *self,
    DBusGMethodInvocation *context)
{
  tp_svc_channel_request_cancel_impl impl = (TP_SVC_CHANNEL_REQUEST_GET_CLASS (self)->cancel_cb);

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
tp_svc_channel_request_implement_cancel (TpSvcChannelRequestClass *klass, tp_svc_channel_request_cancel_impl impl)
{
  klass->cancel_cb = impl;
}

void
tp_svc_channel_request_emit_failed (gpointer instance,
    const gchar *arg_Error,
    const gchar *arg_Message)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_REQUEST));
  g_signal_emit (instance,
      channel_request_signals[SIGNAL_CHANNEL_REQUEST_Failed],
      0,
      arg_Error,
      arg_Message);
}

void
tp_svc_channel_request_emit_succeeded (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_REQUEST));
  g_signal_emit (instance,
      channel_request_signals[SIGNAL_CHANNEL_REQUEST_Succeeded],
      0);
}

void
tp_svc_channel_request_emit_succeeded_with_channel (gpointer instance,
    const gchar *arg_Connection,
    GHashTable *arg_Connection_Properties,
    const gchar *arg_Channel,
    GHashTable *arg_Channel_Properties)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CHANNEL_REQUEST));
  g_signal_emit (instance,
      channel_request_signals[SIGNAL_CHANNEL_REQUEST_SucceededWithChannel],
      0,
      arg_Connection,
      arg_Connection_Properties,
      arg_Channel,
      arg_Channel_Properties);
}

static inline void
tp_svc_channel_request_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[7] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "o", 0, NULL, NULL }, /* Account */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "x", 0, NULL, NULL }, /* UserActionTime */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* PreferredHandler */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aa{sv}", 0, NULL, NULL }, /* Requests */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{sv}", 0, NULL, NULL }, /* Hints */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_channel_request_get_type (),
      &_tp_svc_channel_request_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.ChannelRequest");
  properties[0].name = g_quark_from_static_string ("Account");
  properties[0].type = DBUS_TYPE_G_OBJECT_PATH;
  properties[1].name = g_quark_from_static_string ("UserActionTime");
  properties[1].type = G_TYPE_INT64;
  properties[2].name = g_quark_from_static_string ("PreferredHandler");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("Requests");
  properties[3].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  properties[4].name = g_quark_from_static_string ("Interfaces");
  properties[4].type = G_TYPE_STRV;
  properties[5].name = g_quark_from_static_string ("Hints");
  properties[5].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CHANNEL_REQUEST, &interface);

  channel_request_signals[SIGNAL_CHANNEL_REQUEST_Failed] =
  g_signal_new ("failed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_STRING,
      G_TYPE_STRING);

  channel_request_signals[SIGNAL_CHANNEL_REQUEST_Succeeded] =
  g_signal_new ("succeeded",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  channel_request_signals[SIGNAL_CHANNEL_REQUEST_SucceededWithChannel] =
  g_signal_new ("succeeded-with-channel",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      4,
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

}
static void
tp_svc_channel_request_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_channel_request_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_channel_request_methods[] = {
  { (GCallback) tp_svc_channel_request_proceed, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_channel_request_cancel, g_cclosure_marshal_generic, 52 },
};

static const DBusGObjectInfo _tp_svc_channel_request_object_info = {
  0,
  _tp_svc_channel_request_methods,
  2,
"org.freedesktop.Telepathy.ChannelRequest\0Proceed\0A\0\0org.freedesktop.Telepathy.ChannelRequest\0Cancel\0A\0\0\0",
"org.freedesktop.Telepathy.ChannelRequest\0Failed\0org.freedesktop.Telepathy.ChannelRequest\0Succeeded\0org.freedesktop.Telepathy.ChannelRequest\0SucceededWithChannel\0\0",
"\0\0",
};


