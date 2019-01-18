#include "_gen/tp-svc-connection-manager.h"

static const DBusGObjectInfo _tp_svc_connection_manager_object_info;

struct _TpSvcConnectionManagerClass {
    GTypeInterface parent_class;
    tp_svc_connection_manager_get_parameters_impl get_parameters_cb;
    tp_svc_connection_manager_list_protocols_impl list_protocols_cb;
    tp_svc_connection_manager_request_connection_impl request_connection_cb;
};

enum {
    SIGNAL_CONNECTION_MANAGER_NewConnection,
    N_CONNECTION_MANAGER_SIGNALS
};
static guint connection_manager_signals[N_CONNECTION_MANAGER_SIGNALS] = {0};

static void tp_svc_connection_manager_base_init (gpointer klass);

GType
tp_svc_connection_manager_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionManagerClass),
        tp_svc_connection_manager_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionManager", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_manager_get_parameters (TpSvcConnectionManager *self,
    const gchar *in_Protocol,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_manager_get_parameters_impl impl = (TP_SVC_CONNECTION_MANAGER_GET_CLASS (self)->get_parameters_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Protocol,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_manager_implement_get_parameters (TpSvcConnectionManagerClass *klass, tp_svc_connection_manager_get_parameters_impl impl)
{
  klass->get_parameters_cb = impl;
}

static void
tp_svc_connection_manager_list_protocols (TpSvcConnectionManager *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_manager_list_protocols_impl impl = (TP_SVC_CONNECTION_MANAGER_GET_CLASS (self)->list_protocols_cb);

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
tp_svc_connection_manager_implement_list_protocols (TpSvcConnectionManagerClass *klass, tp_svc_connection_manager_list_protocols_impl impl)
{
  klass->list_protocols_cb = impl;
}

static void
tp_svc_connection_manager_request_connection (TpSvcConnectionManager *self,
    const gchar *in_Protocol,
    GHashTable *in_Parameters,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_manager_request_connection_impl impl = (TP_SVC_CONNECTION_MANAGER_GET_CLASS (self)->request_connection_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Protocol,
        in_Parameters,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_manager_implement_request_connection (TpSvcConnectionManagerClass *klass, tp_svc_connection_manager_request_connection_impl impl)
{
  klass->request_connection_cb = impl;
}

void
tp_svc_connection_manager_emit_new_connection (gpointer instance,
    const gchar *arg_Bus_Name,
    const gchar *arg_Object_Path,
    const gchar *arg_Protocol)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_MANAGER));
  g_signal_emit (instance,
      connection_manager_signals[SIGNAL_CONNECTION_MANAGER_NewConnection],
      0,
      arg_Bus_Name,
      arg_Object_Path,
      arg_Protocol);
}

static inline void
tp_svc_connection_manager_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{sa{sv}}", 0, NULL, NULL }, /* Protocols */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_manager_get_type (),
      &_tp_svc_connection_manager_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.ConnectionManager");
  properties[0].name = g_quark_from_static_string ("Protocols");
  properties[0].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  properties[1].name = g_quark_from_static_string ("Interfaces");
  properties[1].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_MANAGER, &interface);

  connection_manager_signals[SIGNAL_CONNECTION_MANAGER_NewConnection] =
  g_signal_new ("new-connection",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_STRING,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING);

}
static void
tp_svc_connection_manager_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_manager_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_manager_methods[] = {
  { (GCallback) tp_svc_connection_manager_get_parameters, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_manager_list_protocols, g_cclosure_marshal_generic, 99 },
  { (GCallback) tp_svc_connection_manager_request_connection, g_cclosure_marshal_generic, 179 },
};

static const DBusGObjectInfo _tp_svc_connection_manager_object_info = {
  0,
  _tp_svc_connection_manager_methods,
  3,
"org.freedesktop.Telepathy.ConnectionManager\0GetParameters\0A\0Protocol\0I\0s\0Parameters\0O\0F\0N\0a(susv)\0\0org.freedesktop.Telepathy.ConnectionManager\0ListProtocols\0A\0Protocols\0O\0F\0N\0as\0\0org.freedesktop.Telepathy.ConnectionManager\0RequestConnection\0A\0Protocol\0I\0s\0Parameters\0I\0a{sv}\0Bus_Name\0O\0F\0N\0s\0Object_Path\0O\0F\0N\0o\0\0\0",
"org.freedesktop.Telepathy.ConnectionManager\0NewConnection\0\0",
"\0\0",
};


