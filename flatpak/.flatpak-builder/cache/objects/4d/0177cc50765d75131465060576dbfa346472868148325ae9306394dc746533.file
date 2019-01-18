#include "_gen/tp-svc-connection.h"

static const DBusGObjectInfo _tp_svc_connection_object_info;

struct _TpSvcConnectionClass {
    GTypeInterface parent_class;
    tp_svc_connection_connect_impl connect_cb;
    tp_svc_connection_disconnect_impl disconnect_cb;
    tp_svc_connection_get_interfaces_impl get_interfaces_cb;
    tp_svc_connection_get_protocol_impl get_protocol_cb;
    tp_svc_connection_get_self_handle_impl get_self_handle_cb;
    tp_svc_connection_get_status_impl get_status_cb;
    tp_svc_connection_hold_handles_impl hold_handles_cb;
    tp_svc_connection_inspect_handles_impl inspect_handles_cb;
    tp_svc_connection_list_channels_impl list_channels_cb;
    tp_svc_connection_release_handles_impl release_handles_cb;
    tp_svc_connection_request_channel_impl request_channel_cb;
    tp_svc_connection_request_handles_impl request_handles_cb;
    tp_svc_connection_add_client_interest_impl add_client_interest_cb;
    tp_svc_connection_remove_client_interest_impl remove_client_interest_cb;
};

enum {
    SIGNAL_CONNECTION_SelfHandleChanged,
    SIGNAL_CONNECTION_SelfContactChanged,
    SIGNAL_CONNECTION_NewChannel,
    SIGNAL_CONNECTION_ConnectionError,
    SIGNAL_CONNECTION_StatusChanged,
    N_CONNECTION_SIGNALS
};
static guint connection_signals[N_CONNECTION_SIGNALS] = {0};

static void tp_svc_connection_base_init (gpointer klass);

GType
tp_svc_connection_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionClass),
        tp_svc_connection_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnection", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_connect (TpSvcConnection *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_connect_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->connect_cb);

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
tp_svc_connection_implement_connect (TpSvcConnectionClass *klass, tp_svc_connection_connect_impl impl)
{
  klass->connect_cb = impl;
}

static void
tp_svc_connection_disconnect (TpSvcConnection *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_disconnect_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->disconnect_cb);

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
tp_svc_connection_implement_disconnect (TpSvcConnectionClass *klass, tp_svc_connection_disconnect_impl impl)
{
  klass->disconnect_cb = impl;
}

static void
tp_svc_connection_get_interfaces (TpSvcConnection *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_get_interfaces_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->get_interfaces_cb);

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
tp_svc_connection_implement_get_interfaces (TpSvcConnectionClass *klass, tp_svc_connection_get_interfaces_impl impl)
{
  klass->get_interfaces_cb = impl;
}

static void
tp_svc_connection_get_protocol (TpSvcConnection *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_get_protocol_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->get_protocol_cb);

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
tp_svc_connection_implement_get_protocol (TpSvcConnectionClass *klass, tp_svc_connection_get_protocol_impl impl)
{
  klass->get_protocol_cb = impl;
}

static void
tp_svc_connection_get_self_handle (TpSvcConnection *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_get_self_handle_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->get_self_handle_cb);

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
tp_svc_connection_implement_get_self_handle (TpSvcConnectionClass *klass, tp_svc_connection_get_self_handle_impl impl)
{
  klass->get_self_handle_cb = impl;
}

static void
tp_svc_connection_get_status (TpSvcConnection *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_get_status_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->get_status_cb);

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
tp_svc_connection_implement_get_status (TpSvcConnectionClass *klass, tp_svc_connection_get_status_impl impl)
{
  klass->get_status_cb = impl;
}

static void
tp_svc_connection_hold_handles (TpSvcConnection *self,
    guint in_Handle_Type,
    const GArray *in_Handles,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_hold_handles_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->hold_handles_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handle_Type,
        in_Handles,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_implement_hold_handles (TpSvcConnectionClass *klass, tp_svc_connection_hold_handles_impl impl)
{
  klass->hold_handles_cb = impl;
}

static void
tp_svc_connection_inspect_handles (TpSvcConnection *self,
    guint in_Handle_Type,
    const GArray *in_Handles,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_inspect_handles_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->inspect_handles_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handle_Type,
        in_Handles,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_implement_inspect_handles (TpSvcConnectionClass *klass, tp_svc_connection_inspect_handles_impl impl)
{
  klass->inspect_handles_cb = impl;
}

static void
tp_svc_connection_list_channels (TpSvcConnection *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_list_channels_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->list_channels_cb);

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
tp_svc_connection_implement_list_channels (TpSvcConnectionClass *klass, tp_svc_connection_list_channels_impl impl)
{
  klass->list_channels_cb = impl;
}

static void
tp_svc_connection_release_handles (TpSvcConnection *self,
    guint in_Handle_Type,
    const GArray *in_Handles,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_release_handles_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->release_handles_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handle_Type,
        in_Handles,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_implement_release_handles (TpSvcConnectionClass *klass, tp_svc_connection_release_handles_impl impl)
{
  klass->release_handles_cb = impl;
}

static void
tp_svc_connection_request_channel (TpSvcConnection *self,
    const gchar *in_Type,
    guint in_Handle_Type,
    guint in_Handle,
    gboolean in_Suppress_Handler,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_request_channel_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->request_channel_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Type,
        in_Handle_Type,
        in_Handle,
        in_Suppress_Handler,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_implement_request_channel (TpSvcConnectionClass *klass, tp_svc_connection_request_channel_impl impl)
{
  klass->request_channel_cb = impl;
}

static void
tp_svc_connection_request_handles (TpSvcConnection *self,
    guint in_Handle_Type,
    const gchar **in_Identifiers,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_request_handles_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->request_handles_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handle_Type,
        in_Identifiers,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_implement_request_handles (TpSvcConnectionClass *klass, tp_svc_connection_request_handles_impl impl)
{
  klass->request_handles_cb = impl;
}

static void
tp_svc_connection_add_client_interest (TpSvcConnection *self,
    const gchar **in_Tokens,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_add_client_interest_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->add_client_interest_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Tokens,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_implement_add_client_interest (TpSvcConnectionClass *klass, tp_svc_connection_add_client_interest_impl impl)
{
  klass->add_client_interest_cb = impl;
}

static void
tp_svc_connection_remove_client_interest (TpSvcConnection *self,
    const gchar **in_Tokens,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_remove_client_interest_impl impl = (TP_SVC_CONNECTION_GET_CLASS (self)->remove_client_interest_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Tokens,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_implement_remove_client_interest (TpSvcConnectionClass *klass, tp_svc_connection_remove_client_interest_impl impl)
{
  klass->remove_client_interest_cb = impl;
}

void
tp_svc_connection_emit_self_handle_changed (gpointer instance,
    guint arg_Self_Handle)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION));
  g_signal_emit (instance,
      connection_signals[SIGNAL_CONNECTION_SelfHandleChanged],
      0,
      arg_Self_Handle);
}

void
tp_svc_connection_emit_self_contact_changed (gpointer instance,
    guint arg_Self_Handle,
    const gchar *arg_Self_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION));
  g_signal_emit (instance,
      connection_signals[SIGNAL_CONNECTION_SelfContactChanged],
      0,
      arg_Self_Handle,
      arg_Self_ID);
}

void
tp_svc_connection_emit_new_channel (gpointer instance,
    const gchar *arg_Object_Path,
    const gchar *arg_Channel_Type,
    guint arg_Handle_Type,
    guint arg_Handle,
    gboolean arg_Suppress_Handler)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION));
  g_signal_emit (instance,
      connection_signals[SIGNAL_CONNECTION_NewChannel],
      0,
      arg_Object_Path,
      arg_Channel_Type,
      arg_Handle_Type,
      arg_Handle,
      arg_Suppress_Handler);
}

void
tp_svc_connection_emit_connection_error (gpointer instance,
    const gchar *arg_Error,
    GHashTable *arg_Details)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION));
  g_signal_emit (instance,
      connection_signals[SIGNAL_CONNECTION_ConnectionError],
      0,
      arg_Error,
      arg_Details);
}

void
tp_svc_connection_emit_status_changed (gpointer instance,
    guint arg_Status,
    guint arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION));
  g_signal_emit (instance,
      connection_signals[SIGNAL_CONNECTION_StatusChanged],
      0,
      arg_Status,
      arg_Reason);
}

static inline void
tp_svc_connection_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* SelfHandle */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* SelfID */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Status */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* HasImmortalHandles */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_get_type (),
      &_tp_svc_connection_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("SelfHandle");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("SelfID");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("Status");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("HasImmortalHandles");
  properties[4].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION, &interface);

  connection_signals[SIGNAL_CONNECTION_SelfHandleChanged] =
  g_signal_new ("self-handle-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  connection_signals[SIGNAL_CONNECTION_SelfContactChanged] =
  g_signal_new ("self-contact-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_STRING);

  connection_signals[SIGNAL_CONNECTION_NewChannel] =
  g_signal_new ("new-channel",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      5,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_BOOLEAN);

  connection_signals[SIGNAL_CONNECTION_ConnectionError] =
  g_signal_new ("connection-error",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

  connection_signals[SIGNAL_CONNECTION_StatusChanged] =
  g_signal_new ("status-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_connection_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_methods[] = {
  { (GCallback) tp_svc_connection_connect, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_disconnect, g_cclosure_marshal_generic, 48 },
  { (GCallback) tp_svc_connection_get_interfaces, g_cclosure_marshal_generic, 99 },
  { (GCallback) tp_svc_connection_get_protocol, g_cclosure_marshal_generic, 173 },
  { (GCallback) tp_svc_connection_get_self_handle, g_cclosure_marshal_generic, 242 },
  { (GCallback) tp_svc_connection_get_status, g_cclosure_marshal_generic, 316 },
  { (GCallback) tp_svc_connection_hold_handles, g_cclosure_marshal_generic, 381 },
  { (GCallback) tp_svc_connection_inspect_handles, g_cclosure_marshal_generic, 462 },
  { (GCallback) tp_svc_connection_list_channels, g_cclosure_marshal_generic, 567 },
  { (GCallback) tp_svc_connection_release_handles, g_cclosure_marshal_generic, 647 },
  { (GCallback) tp_svc_connection_request_channel, g_cclosure_marshal_generic, 731 },
  { (GCallback) tp_svc_connection_request_handles, g_cclosure_marshal_generic, 863 },
  { (GCallback) tp_svc_connection_add_client_interest, g_cclosure_marshal_generic, 968 },
  { (GCallback) tp_svc_connection_remove_client_interest, g_cclosure_marshal_generic, 1038 },
};

static const DBusGObjectInfo _tp_svc_connection_object_info = {
  0,
  _tp_svc_connection_methods,
  14,
"org.freedesktop.Telepathy.Connection\0Connect\0A\0\0org.freedesktop.Telepathy.Connection\0Disconnect\0A\0\0org.freedesktop.Telepathy.Connection\0GetInterfaces\0A\0Interfaces\0O\0F\0N\0as\0\0org.freedesktop.Telepathy.Connection\0GetProtocol\0A\0Protocol\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Connection\0GetSelfHandle\0A\0Self_Handle\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Connection\0GetStatus\0A\0Status\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Connection\0HoldHandles\0A\0Handle_Type\0I\0u\0Handles\0I\0au\0\0org.freedesktop.Telepathy.Connection\0InspectHandles\0A\0Handle_Type\0I\0u\0Handles\0I\0au\0Identifiers\0O\0F\0N\0as\0\0org.freedesktop.Telepathy.Connection\0ListChannels\0A\0Channel_Info\0O\0F\0N\0a(osuu)\0\0org.freedesktop.Telepathy.Connection\0ReleaseHandles\0A\0Handle_Type\0I\0u\0Handles\0I\0au\0\0org.freedesktop.Telepathy.Connection\0RequestChannel\0A\0Type\0I\0s\0Handle_Type\0I\0u\0Handle\0I\0u\0Suppress_Handler\0I\0b\0Object_Path\0O\0F\0N\0o\0\0org.freedesktop.Telepathy.Connection\0RequestHandles\0A\0Handle_Type\0I\0u\0Identifiers\0I\0as\0Handles\0O\0F\0N\0au\0\0org.freedesktop.Telepathy.Connection\0AddClientInterest\0A\0Tokens\0I\0as\0\0org.freedesktop.Telepathy.Connection\0RemoveClientInterest\0A\0Tokens\0I\0as\0\0\0",
"org.freedesktop.Telepathy.Connection\0SelfHandleChanged\0org.freedesktop.Telepathy.Connection\0SelfContactChanged\0org.freedesktop.Telepathy.Connection\0NewChannel\0org.freedesktop.Telepathy.Connection\0ConnectionError\0org.freedesktop.Telepathy.Connection\0StatusChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_addressing_object_info;

struct _TpSvcConnectionInterfaceAddressingClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_addressing_get_contacts_by_vcard_field_impl get_contacts_by_vcard_field_cb;
    tp_svc_connection_interface_addressing_get_contacts_by_uri_impl get_contacts_by_uri_cb;
};

static void tp_svc_connection_interface_addressing_base_init (gpointer klass);

GType
tp_svc_connection_interface_addressing_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceAddressingClass),
        tp_svc_connection_interface_addressing_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceAddressing", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_addressing_get_contacts_by_vcard_field (TpSvcConnectionInterfaceAddressing *self,
    const gchar *in_Field,
    const gchar **in_Addresses,
    const gchar **in_Interfaces,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_addressing_get_contacts_by_vcard_field_impl impl = (TP_SVC_CONNECTION_INTERFACE_ADDRESSING_GET_CLASS (self)->get_contacts_by_vcard_field_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Field,
        in_Addresses,
        in_Interfaces,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_addressing_implement_get_contacts_by_vcard_field (TpSvcConnectionInterfaceAddressingClass *klass, tp_svc_connection_interface_addressing_get_contacts_by_vcard_field_impl impl)
{
  klass->get_contacts_by_vcard_field_cb = impl;
}

static void
tp_svc_connection_interface_addressing_get_contacts_by_uri (TpSvcConnectionInterfaceAddressing *self,
    const gchar **in_URIs,
    const gchar **in_Interfaces,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_addressing_get_contacts_by_uri_impl impl = (TP_SVC_CONNECTION_INTERFACE_ADDRESSING_GET_CLASS (self)->get_contacts_by_uri_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_URIs,
        in_Interfaces,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_addressing_implement_get_contacts_by_uri (TpSvcConnectionInterfaceAddressingClass *klass, tp_svc_connection_interface_addressing_get_contacts_by_uri_impl impl)
{
  klass->get_contacts_by_uri_cb = impl;
}

static inline void
tp_svc_connection_interface_addressing_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_connection_interface_addressing_get_type (),
      &_tp_svc_connection_interface_addressing_object_info);

}
static void
tp_svc_connection_interface_addressing_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_addressing_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_addressing_methods[] = {
  { (GCallback) tp_svc_connection_interface_addressing_get_contacts_by_vcard_field, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_addressing_get_contacts_by_uri, g_cclosure_marshal_generic, 176 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_addressing_object_info = {
  0,
  _tp_svc_connection_interface_addressing_methods,
  2,
"org.freedesktop.Telepathy.Connection.Interface.Addressing1\0GetContactsByVCardField\0A\0Field\0I\0s\0Addresses\0I\0as\0Interfaces\0I\0as\0Requested\0O\0F\0N\0a{su}\0Attributes\0O\0F\0N\0a{ua{sv}}\0\0org.freedesktop.Telepathy.Connection.Interface.Addressing1\0GetContactsByURI\0A\0URIs\0I\0as\0Interfaces\0I\0as\0Requested\0O\0F\0N\0a{su}\0Attributes\0O\0F\0N\0a{ua{sv}}\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_aliasing_object_info;

struct _TpSvcConnectionInterfaceAliasingClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_aliasing_get_alias_flags_impl get_alias_flags_cb;
    tp_svc_connection_interface_aliasing_request_aliases_impl request_aliases_cb;
    tp_svc_connection_interface_aliasing_get_aliases_impl get_aliases_cb;
    tp_svc_connection_interface_aliasing_set_aliases_impl set_aliases_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_ALIASING_AliasesChanged,
    N_CONNECTION_INTERFACE_ALIASING_SIGNALS
};
static guint connection_interface_aliasing_signals[N_CONNECTION_INTERFACE_ALIASING_SIGNALS] = {0};

static void tp_svc_connection_interface_aliasing_base_init (gpointer klass);

GType
tp_svc_connection_interface_aliasing_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceAliasingClass),
        tp_svc_connection_interface_aliasing_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceAliasing", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_aliasing_get_alias_flags (TpSvcConnectionInterfaceAliasing *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_aliasing_get_alias_flags_impl impl = (TP_SVC_CONNECTION_INTERFACE_ALIASING_GET_CLASS (self)->get_alias_flags_cb);

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
tp_svc_connection_interface_aliasing_implement_get_alias_flags (TpSvcConnectionInterfaceAliasingClass *klass, tp_svc_connection_interface_aliasing_get_alias_flags_impl impl)
{
  klass->get_alias_flags_cb = impl;
}

static void
tp_svc_connection_interface_aliasing_request_aliases (TpSvcConnectionInterfaceAliasing *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_aliasing_request_aliases_impl impl = (TP_SVC_CONNECTION_INTERFACE_ALIASING_GET_CLASS (self)->request_aliases_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_aliasing_implement_request_aliases (TpSvcConnectionInterfaceAliasingClass *klass, tp_svc_connection_interface_aliasing_request_aliases_impl impl)
{
  klass->request_aliases_cb = impl;
}

static void
tp_svc_connection_interface_aliasing_get_aliases (TpSvcConnectionInterfaceAliasing *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_aliasing_get_aliases_impl impl = (TP_SVC_CONNECTION_INTERFACE_ALIASING_GET_CLASS (self)->get_aliases_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_aliasing_implement_get_aliases (TpSvcConnectionInterfaceAliasingClass *klass, tp_svc_connection_interface_aliasing_get_aliases_impl impl)
{
  klass->get_aliases_cb = impl;
}

static void
tp_svc_connection_interface_aliasing_set_aliases (TpSvcConnectionInterfaceAliasing *self,
    GHashTable *in_Aliases,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_aliasing_set_aliases_impl impl = (TP_SVC_CONNECTION_INTERFACE_ALIASING_GET_CLASS (self)->set_aliases_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Aliases,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_aliasing_implement_set_aliases (TpSvcConnectionInterfaceAliasingClass *klass, tp_svc_connection_interface_aliasing_set_aliases_impl impl)
{
  klass->set_aliases_cb = impl;
}

void
tp_svc_connection_interface_aliasing_emit_aliases_changed (gpointer instance,
    const GPtrArray *arg_Aliases)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_ALIASING));
  g_signal_emit (instance,
      connection_interface_aliasing_signals[SIGNAL_CONNECTION_INTERFACE_ALIASING_AliasesChanged],
      0,
      arg_Aliases);
}

static inline void
tp_svc_connection_interface_aliasing_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_connection_interface_aliasing_get_type (),
      &_tp_svc_connection_interface_aliasing_object_info);

  connection_interface_aliasing_signals[SIGNAL_CONNECTION_INTERFACE_ALIASING_AliasesChanged] =
  g_signal_new ("aliases-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));

}
static void
tp_svc_connection_interface_aliasing_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_aliasing_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_aliasing_methods[] = {
  { (GCallback) tp_svc_connection_interface_aliasing_get_alias_flags, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_aliasing_request_aliases, g_cclosure_marshal_generic, 93 },
  { (GCallback) tp_svc_connection_interface_aliasing_get_aliases, g_cclosure_marshal_generic, 198 },
  { (GCallback) tp_svc_connection_interface_aliasing_set_aliases, g_cclosure_marshal_generic, 302 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_aliasing_object_info = {
  0,
  _tp_svc_connection_interface_aliasing_methods,
  4,
"org.freedesktop.Telepathy.Connection.Interface.Aliasing\0GetAliasFlags\0A\0Alias_Flags\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Connection.Interface.Aliasing\0RequestAliases\0A\0Contacts\0I\0au\0Aliases\0O\0F\0N\0as\0\0org.freedesktop.Telepathy.Connection.Interface.Aliasing\0GetAliases\0A\0Contacts\0I\0au\0Aliases\0O\0F\0N\0a{us}\0\0org.freedesktop.Telepathy.Connection.Interface.Aliasing\0SetAliases\0A\0Aliases\0I\0a{us}\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.Aliasing\0AliasesChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_anonymity_object_info;

struct _TpSvcConnectionInterfaceAnonymityClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_ANONYMITY_AnonymityModesChanged,
    N_CONNECTION_INTERFACE_ANONYMITY_SIGNALS
};
static guint connection_interface_anonymity_signals[N_CONNECTION_INTERFACE_ANONYMITY_SIGNALS] = {0};

static void tp_svc_connection_interface_anonymity_base_init (gpointer klass);

GType
tp_svc_connection_interface_anonymity_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceAnonymityClass),
        tp_svc_connection_interface_anonymity_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceAnonymity", &info, 0);
    }

  return type;
}

void
tp_svc_connection_interface_anonymity_emit_anonymity_modes_changed (gpointer instance,
    guint arg_Modes)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_ANONYMITY));
  g_signal_emit (instance,
      connection_interface_anonymity_signals[SIGNAL_CONNECTION_INTERFACE_ANONYMITY_AnonymityModesChanged],
      0,
      arg_Modes);
}

static inline void
tp_svc_connection_interface_anonymity_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* SupportedAnonymityModes */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "b", 0, NULL, NULL }, /* AnonymityMandatory */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "u", 0, NULL, NULL }, /* AnonymityModes */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_anonymity_get_type (),
      &_tp_svc_connection_interface_anonymity_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.Anonymity");
  properties[0].name = g_quark_from_static_string ("SupportedAnonymityModes");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("AnonymityMandatory");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("AnonymityModes");
  properties[2].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_ANONYMITY, &interface);

  connection_interface_anonymity_signals[SIGNAL_CONNECTION_INTERFACE_ANONYMITY_AnonymityModesChanged] =
  g_signal_new ("anonymity-modes-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

}
static void
tp_svc_connection_interface_anonymity_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_anonymity_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_anonymity_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_connection_interface_anonymity_object_info = {
  0,
  _tp_svc_connection_interface_anonymity_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Connection.Interface.Anonymity\0AnonymityModesChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_avatars_object_info;

struct _TpSvcConnectionInterfaceAvatarsClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_avatars_get_avatar_requirements_impl get_avatar_requirements_cb;
    tp_svc_connection_interface_avatars_get_avatar_tokens_impl get_avatar_tokens_cb;
    tp_svc_connection_interface_avatars_get_known_avatar_tokens_impl get_known_avatar_tokens_cb;
    tp_svc_connection_interface_avatars_request_avatar_impl request_avatar_cb;
    tp_svc_connection_interface_avatars_request_avatars_impl request_avatars_cb;
    tp_svc_connection_interface_avatars_set_avatar_impl set_avatar_cb;
    tp_svc_connection_interface_avatars_clear_avatar_impl clear_avatar_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_AVATARS_AvatarUpdated,
    SIGNAL_CONNECTION_INTERFACE_AVATARS_AvatarRetrieved,
    N_CONNECTION_INTERFACE_AVATARS_SIGNALS
};
static guint connection_interface_avatars_signals[N_CONNECTION_INTERFACE_AVATARS_SIGNALS] = {0};

static void tp_svc_connection_interface_avatars_base_init (gpointer klass);

GType
tp_svc_connection_interface_avatars_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceAvatarsClass),
        tp_svc_connection_interface_avatars_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceAvatars", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_avatars_get_avatar_requirements (TpSvcConnectionInterfaceAvatars *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_avatars_get_avatar_requirements_impl impl = (TP_SVC_CONNECTION_INTERFACE_AVATARS_GET_CLASS (self)->get_avatar_requirements_cb);

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
tp_svc_connection_interface_avatars_implement_get_avatar_requirements (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_get_avatar_requirements_impl impl)
{
  klass->get_avatar_requirements_cb = impl;
}

static void
tp_svc_connection_interface_avatars_get_avatar_tokens (TpSvcConnectionInterfaceAvatars *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_avatars_get_avatar_tokens_impl impl = (TP_SVC_CONNECTION_INTERFACE_AVATARS_GET_CLASS (self)->get_avatar_tokens_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_avatars_implement_get_avatar_tokens (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_get_avatar_tokens_impl impl)
{
  klass->get_avatar_tokens_cb = impl;
}

static void
tp_svc_connection_interface_avatars_get_known_avatar_tokens (TpSvcConnectionInterfaceAvatars *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_avatars_get_known_avatar_tokens_impl impl = (TP_SVC_CONNECTION_INTERFACE_AVATARS_GET_CLASS (self)->get_known_avatar_tokens_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_avatars_implement_get_known_avatar_tokens (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_get_known_avatar_tokens_impl impl)
{
  klass->get_known_avatar_tokens_cb = impl;
}

static void
tp_svc_connection_interface_avatars_request_avatar (TpSvcConnectionInterfaceAvatars *self,
    guint in_Contact,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_avatars_request_avatar_impl impl = (TP_SVC_CONNECTION_INTERFACE_AVATARS_GET_CLASS (self)->request_avatar_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contact,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_avatars_implement_request_avatar (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_request_avatar_impl impl)
{
  klass->request_avatar_cb = impl;
}

static void
tp_svc_connection_interface_avatars_request_avatars (TpSvcConnectionInterfaceAvatars *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_avatars_request_avatars_impl impl = (TP_SVC_CONNECTION_INTERFACE_AVATARS_GET_CLASS (self)->request_avatars_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_avatars_implement_request_avatars (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_request_avatars_impl impl)
{
  klass->request_avatars_cb = impl;
}

static void
tp_svc_connection_interface_avatars_set_avatar (TpSvcConnectionInterfaceAvatars *self,
    const GArray *in_Avatar,
    const gchar *in_MIME_Type,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_avatars_set_avatar_impl impl = (TP_SVC_CONNECTION_INTERFACE_AVATARS_GET_CLASS (self)->set_avatar_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Avatar,
        in_MIME_Type,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_avatars_implement_set_avatar (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_set_avatar_impl impl)
{
  klass->set_avatar_cb = impl;
}

static void
tp_svc_connection_interface_avatars_clear_avatar (TpSvcConnectionInterfaceAvatars *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_avatars_clear_avatar_impl impl = (TP_SVC_CONNECTION_INTERFACE_AVATARS_GET_CLASS (self)->clear_avatar_cb);

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
tp_svc_connection_interface_avatars_implement_clear_avatar (TpSvcConnectionInterfaceAvatarsClass *klass, tp_svc_connection_interface_avatars_clear_avatar_impl impl)
{
  klass->clear_avatar_cb = impl;
}

void
tp_svc_connection_interface_avatars_emit_avatar_updated (gpointer instance,
    guint arg_Contact,
    const gchar *arg_New_Avatar_Token)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_AVATARS));
  g_signal_emit (instance,
      connection_interface_avatars_signals[SIGNAL_CONNECTION_INTERFACE_AVATARS_AvatarUpdated],
      0,
      arg_Contact,
      arg_New_Avatar_Token);
}

void
tp_svc_connection_interface_avatars_emit_avatar_retrieved (gpointer instance,
    guint arg_Contact,
    const gchar *arg_Token,
    const GArray *arg_Avatar,
    const gchar *arg_Type)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_AVATARS));
  g_signal_emit (instance,
      connection_interface_avatars_signals[SIGNAL_CONNECTION_INTERFACE_AVATARS_AvatarRetrieved],
      0,
      arg_Contact,
      arg_Token,
      arg_Avatar,
      arg_Type);
}

static inline void
tp_svc_connection_interface_avatars_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[9] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* SupportedAvatarMIMETypes */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MinimumAvatarHeight */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MinimumAvatarWidth */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* RecommendedAvatarHeight */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* RecommendedAvatarWidth */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MaximumAvatarHeight */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MaximumAvatarWidth */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MaximumAvatarBytes */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_avatars_get_type (),
      &_tp_svc_connection_interface_avatars_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.Avatars");
  properties[0].name = g_quark_from_static_string ("SupportedAvatarMIMETypes");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("MinimumAvatarHeight");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("MinimumAvatarWidth");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("RecommendedAvatarHeight");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("RecommendedAvatarWidth");
  properties[4].type = G_TYPE_UINT;
  properties[5].name = g_quark_from_static_string ("MaximumAvatarHeight");
  properties[5].type = G_TYPE_UINT;
  properties[6].name = g_quark_from_static_string ("MaximumAvatarWidth");
  properties[6].type = G_TYPE_UINT;
  properties[7].name = g_quark_from_static_string ("MaximumAvatarBytes");
  properties[7].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_AVATARS, &interface);

  connection_interface_avatars_signals[SIGNAL_CONNECTION_INTERFACE_AVATARS_AvatarUpdated] =
  g_signal_new ("avatar-updated",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_STRING);

  connection_interface_avatars_signals[SIGNAL_CONNECTION_INTERFACE_AVATARS_AvatarRetrieved] =
  g_signal_new ("avatar-retrieved",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      4,
      G_TYPE_UINT,
      G_TYPE_STRING,
      dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR),
      G_TYPE_STRING);

}
static void
tp_svc_connection_interface_avatars_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_avatars_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_avatars_methods[] = {
  { (GCallback) tp_svc_connection_interface_avatars_get_avatar_requirements, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_avatars_get_avatar_tokens, g_cclosure_marshal_generic, 192 },
  { (GCallback) tp_svc_connection_interface_avatars_get_known_avatar_tokens, g_cclosure_marshal_generic, 296 },
  { (GCallback) tp_svc_connection_interface_avatars_request_avatar, g_cclosure_marshal_generic, 408 },
  { (GCallback) tp_svc_connection_interface_avatars_request_avatars, g_cclosure_marshal_generic, 524 },
  { (GCallback) tp_svc_connection_interface_avatars_set_avatar, g_cclosure_marshal_generic, 611 },
  { (GCallback) tp_svc_connection_interface_avatars_clear_avatar, g_cclosure_marshal_generic, 719 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_avatars_object_info = {
  0,
  _tp_svc_connection_interface_avatars_methods,
  7,
"org.freedesktop.Telepathy.Connection.Interface.Avatars\0GetAvatarRequirements\0A\0MIME_Types\0O\0F\0N\0as\0Min_Width\0O\0F\0N\0q\0Min_Height\0O\0F\0N\0q\0Max_Width\0O\0F\0N\0q\0Max_Height\0O\0F\0N\0q\0Max_Bytes\0O\0F\0N\0u\0\0org.freedesktop.Telepathy.Connection.Interface.Avatars\0GetAvatarTokens\0A\0Contacts\0I\0au\0Tokens\0O\0F\0N\0as\0\0org.freedesktop.Telepathy.Connection.Interface.Avatars\0GetKnownAvatarTokens\0A\0Contacts\0I\0au\0Tokens\0O\0F\0N\0a{us}\0\0org.freedesktop.Telepathy.Connection.Interface.Avatars\0RequestAvatar\0A\0Contact\0I\0u\0Data\0O\0F\0N\0ay\0MIME_Type\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Connection.Interface.Avatars\0RequestAvatars\0A\0Contacts\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.Avatars\0SetAvatar\0A\0Avatar\0I\0ay\0MIME_Type\0I\0s\0Token\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Connection.Interface.Avatars\0ClearAvatar\0A\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.Avatars\0AvatarUpdated\0org.freedesktop.Telepathy.Connection.Interface.Avatars\0AvatarRetrieved\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_balance_object_info;

struct _TpSvcConnectionInterfaceBalanceClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_BALANCE_BalanceChanged,
    N_CONNECTION_INTERFACE_BALANCE_SIGNALS
};
static guint connection_interface_balance_signals[N_CONNECTION_INTERFACE_BALANCE_SIGNALS] = {0};

static void tp_svc_connection_interface_balance_base_init (gpointer klass);

GType
tp_svc_connection_interface_balance_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceBalanceClass),
        tp_svc_connection_interface_balance_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceBalance", &info, 0);
    }

  return type;
}

void
tp_svc_connection_interface_balance_emit_balance_changed (gpointer instance,
    const GValueArray *arg_Balance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_BALANCE));
  g_signal_emit (instance,
      connection_interface_balance_signals[SIGNAL_CONNECTION_INTERFACE_BALANCE_BalanceChanged],
      0,
      arg_Balance);
}

static inline void
tp_svc_connection_interface_balance_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(ius)", 0, NULL, NULL }, /* AccountBalance */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* ManageCreditURI */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_balance_get_type (),
      &_tp_svc_connection_interface_balance_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.Balance");
  properties[0].name = g_quark_from_static_string ("AccountBalance");
  properties[0].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_INT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID));
  properties[1].name = g_quark_from_static_string ("ManageCreditURI");
  properties[1].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_BALANCE, &interface);

  connection_interface_balance_signals[SIGNAL_CONNECTION_INTERFACE_BALANCE_BalanceChanged] =
  g_signal_new ("balance-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_INT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)));

}
static void
tp_svc_connection_interface_balance_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_balance_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_balance_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_connection_interface_balance_object_info = {
  0,
  _tp_svc_connection_interface_balance_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Connection.Interface.Balance\0BalanceChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_capabilities_object_info;

struct _TpSvcConnectionInterfaceCapabilitiesClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_capabilities_advertise_capabilities_impl advertise_capabilities_cb;
    tp_svc_connection_interface_capabilities_get_capabilities_impl get_capabilities_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_CAPABILITIES_CapabilitiesChanged,
    N_CONNECTION_INTERFACE_CAPABILITIES_SIGNALS
};
static guint connection_interface_capabilities_signals[N_CONNECTION_INTERFACE_CAPABILITIES_SIGNALS] = {0};

static void tp_svc_connection_interface_capabilities_base_init (gpointer klass);

GType
tp_svc_connection_interface_capabilities_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceCapabilitiesClass),
        tp_svc_connection_interface_capabilities_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceCapabilities", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_capabilities_advertise_capabilities (TpSvcConnectionInterfaceCapabilities *self,
    const GPtrArray *in_Add,
    const gchar **in_Remove,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_capabilities_advertise_capabilities_impl impl = (TP_SVC_CONNECTION_INTERFACE_CAPABILITIES_GET_CLASS (self)->advertise_capabilities_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Add,
        in_Remove,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_capabilities_implement_advertise_capabilities (TpSvcConnectionInterfaceCapabilitiesClass *klass, tp_svc_connection_interface_capabilities_advertise_capabilities_impl impl)
{
  klass->advertise_capabilities_cb = impl;
}

static void
tp_svc_connection_interface_capabilities_get_capabilities (TpSvcConnectionInterfaceCapabilities *self,
    const GArray *in_Handles,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_capabilities_get_capabilities_impl impl = (TP_SVC_CONNECTION_INTERFACE_CAPABILITIES_GET_CLASS (self)->get_capabilities_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handles,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_capabilities_implement_get_capabilities (TpSvcConnectionInterfaceCapabilitiesClass *klass, tp_svc_connection_interface_capabilities_get_capabilities_impl impl)
{
  klass->get_capabilities_cb = impl;
}

void
tp_svc_connection_interface_capabilities_emit_capabilities_changed (gpointer instance,
    const GPtrArray *arg_Caps)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CAPABILITIES));
  g_signal_emit (instance,
      connection_interface_capabilities_signals[SIGNAL_CONNECTION_INTERFACE_CAPABILITIES_CapabilitiesChanged],
      0,
      arg_Caps);
}

static inline void
tp_svc_connection_interface_capabilities_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_connection_interface_capabilities_get_type (),
      &_tp_svc_connection_interface_capabilities_object_info);

  connection_interface_capabilities_signals[SIGNAL_CONNECTION_INTERFACE_CAPABILITIES_CapabilitiesChanged] =
  g_signal_new ("capabilities-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))));

}
static void
tp_svc_connection_interface_capabilities_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_capabilities_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_capabilities_methods[] = {
  { (GCallback) tp_svc_connection_interface_capabilities_advertise_capabilities, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_capabilities_get_capabilities, g_cclosure_marshal_generic, 139 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_capabilities_object_info = {
  0,
  _tp_svc_connection_interface_capabilities_methods,
  2,
"org.freedesktop.Telepathy.Connection.Interface.Capabilities\0AdvertiseCapabilities\0A\0Add\0I\0a(su)\0Remove\0I\0as\0Self_Capabilities\0O\0F\0N\0a(su)\0\0org.freedesktop.Telepathy.Connection.Interface.Capabilities\0GetCapabilities\0A\0Handles\0I\0au\0Contact_Capabilities\0O\0F\0N\0a(usuu)\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.Capabilities\0CapabilitiesChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_cellular_object_info;

struct _TpSvcConnectionInterfaceCellularClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_CELLULAR_IMSIChanged,
    N_CONNECTION_INTERFACE_CELLULAR_SIGNALS
};
static guint connection_interface_cellular_signals[N_CONNECTION_INTERFACE_CELLULAR_SIGNALS] = {0};

static void tp_svc_connection_interface_cellular_base_init (gpointer klass);

GType
tp_svc_connection_interface_cellular_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceCellularClass),
        tp_svc_connection_interface_cellular_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceCellular", &info, 0);
    }

  return type;
}

void
tp_svc_connection_interface_cellular_emit_imsi_changed (gpointer instance,
    const gchar *arg_IMSI)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CELLULAR));
  g_signal_emit (instance,
      connection_interface_cellular_signals[SIGNAL_CONNECTION_INTERFACE_CELLULAR_IMSIChanged],
      0,
      arg_IMSI);
}

static inline void
tp_svc_connection_interface_cellular_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[7] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "u", 0, NULL, NULL }, /* MessageValidityPeriod */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "b", 0, NULL, NULL }, /* OverrideMessageServiceCentre */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "s", 0, NULL, NULL }, /* MessageServiceCentre */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* IMSI */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "b", 0, NULL, NULL }, /* MessageReducedCharacterSet */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "s", 0, NULL, NULL }, /* MessageNationalCharacterSet */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_cellular_get_type (),
      &_tp_svc_connection_interface_cellular_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.Cellular");
  properties[0].name = g_quark_from_static_string ("MessageValidityPeriod");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("OverrideMessageServiceCentre");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("MessageServiceCentre");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("IMSI");
  properties[3].type = G_TYPE_STRING;
  properties[4].name = g_quark_from_static_string ("MessageReducedCharacterSet");
  properties[4].type = G_TYPE_BOOLEAN;
  properties[5].name = g_quark_from_static_string ("MessageNationalCharacterSet");
  properties[5].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_CELLULAR, &interface);

  connection_interface_cellular_signals[SIGNAL_CONNECTION_INTERFACE_CELLULAR_IMSIChanged] =
  g_signal_new ("i-ms-ichanged",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRING);

}
static void
tp_svc_connection_interface_cellular_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_cellular_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_cellular_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_connection_interface_cellular_object_info = {
  0,
  _tp_svc_connection_interface_cellular_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Connection.Interface.Cellular\0IMSIChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_client_types_object_info;

struct _TpSvcConnectionInterfaceClientTypesClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_client_types_get_client_types_impl get_client_types_cb;
    tp_svc_connection_interface_client_types_request_client_types_impl request_client_types_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_CLIENT_TYPES_ClientTypesUpdated,
    N_CONNECTION_INTERFACE_CLIENT_TYPES_SIGNALS
};
static guint connection_interface_client_types_signals[N_CONNECTION_INTERFACE_CLIENT_TYPES_SIGNALS] = {0};

static void tp_svc_connection_interface_client_types_base_init (gpointer klass);

GType
tp_svc_connection_interface_client_types_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceClientTypesClass),
        tp_svc_connection_interface_client_types_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceClientTypes", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_client_types_get_client_types (TpSvcConnectionInterfaceClientTypes *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_client_types_get_client_types_impl impl = (TP_SVC_CONNECTION_INTERFACE_CLIENT_TYPES_GET_CLASS (self)->get_client_types_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_client_types_implement_get_client_types (TpSvcConnectionInterfaceClientTypesClass *klass, tp_svc_connection_interface_client_types_get_client_types_impl impl)
{
  klass->get_client_types_cb = impl;
}

static void
tp_svc_connection_interface_client_types_request_client_types (TpSvcConnectionInterfaceClientTypes *self,
    guint in_Contact,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_client_types_request_client_types_impl impl = (TP_SVC_CONNECTION_INTERFACE_CLIENT_TYPES_GET_CLASS (self)->request_client_types_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contact,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_client_types_implement_request_client_types (TpSvcConnectionInterfaceClientTypesClass *klass, tp_svc_connection_interface_client_types_request_client_types_impl impl)
{
  klass->request_client_types_cb = impl;
}

void
tp_svc_connection_interface_client_types_emit_client_types_updated (gpointer instance,
    guint arg_Contact,
    const gchar **arg_Client_Types)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CLIENT_TYPES));
  g_signal_emit (instance,
      connection_interface_client_types_signals[SIGNAL_CONNECTION_INTERFACE_CLIENT_TYPES_ClientTypesUpdated],
      0,
      arg_Contact,
      arg_Client_Types);
}

static inline void
tp_svc_connection_interface_client_types_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_connection_interface_client_types_get_type (),
      &_tp_svc_connection_interface_client_types_object_info);

  connection_interface_client_types_signals[SIGNAL_CONNECTION_INTERFACE_CLIENT_TYPES_ClientTypesUpdated] =
  g_signal_new ("client-types-updated",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_STRV);

}
static void
tp_svc_connection_interface_client_types_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_client_types_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_client_types_methods[] = {
  { (GCallback) tp_svc_connection_interface_client_types_get_client_types, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_client_types_request_client_types, g_cclosure_marshal_generic, 117 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_client_types_object_info = {
  0,
  _tp_svc_connection_interface_client_types_methods,
  2,
"org.freedesktop.Telepathy.Connection.Interface.ClientTypes\0GetClientTypes\0A\0Contacts\0I\0au\0Client_Types\0O\0F\0N\0a{uas}\0\0org.freedesktop.Telepathy.Connection.Interface.ClientTypes\0RequestClientTypes\0A\0Contact\0I\0u\0Client_Types\0O\0F\0N\0as\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.ClientTypes\0ClientTypesUpdated\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_blocking_object_info;

struct _TpSvcConnectionInterfaceContactBlockingClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_contact_blocking_block_contacts_impl block_contacts_cb;
    tp_svc_connection_interface_contact_blocking_unblock_contacts_impl unblock_contacts_cb;
    tp_svc_connection_interface_contact_blocking_request_blocked_contacts_impl request_blocked_contacts_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_CONTACT_BLOCKING_BlockedContactsChanged,
    N_CONNECTION_INTERFACE_CONTACT_BLOCKING_SIGNALS
};
static guint connection_interface_contact_blocking_signals[N_CONNECTION_INTERFACE_CONTACT_BLOCKING_SIGNALS] = {0};

static void tp_svc_connection_interface_contact_blocking_base_init (gpointer klass);

GType
tp_svc_connection_interface_contact_blocking_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceContactBlockingClass),
        tp_svc_connection_interface_contact_blocking_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceContactBlocking", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_contact_blocking_block_contacts (TpSvcConnectionInterfaceContactBlocking *self,
    const GArray *in_Contacts,
    gboolean in_Report_Abusive,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_blocking_block_contacts_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING_GET_CLASS (self)->block_contacts_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        in_Report_Abusive,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_blocking_implement_block_contacts (TpSvcConnectionInterfaceContactBlockingClass *klass, tp_svc_connection_interface_contact_blocking_block_contacts_impl impl)
{
  klass->block_contacts_cb = impl;
}

static void
tp_svc_connection_interface_contact_blocking_unblock_contacts (TpSvcConnectionInterfaceContactBlocking *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_blocking_unblock_contacts_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING_GET_CLASS (self)->unblock_contacts_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_blocking_implement_unblock_contacts (TpSvcConnectionInterfaceContactBlockingClass *klass, tp_svc_connection_interface_contact_blocking_unblock_contacts_impl impl)
{
  klass->unblock_contacts_cb = impl;
}

static void
tp_svc_connection_interface_contact_blocking_request_blocked_contacts (TpSvcConnectionInterfaceContactBlocking *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_blocking_request_blocked_contacts_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING_GET_CLASS (self)->request_blocked_contacts_cb);

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
tp_svc_connection_interface_contact_blocking_implement_request_blocked_contacts (TpSvcConnectionInterfaceContactBlockingClass *klass, tp_svc_connection_interface_contact_blocking_request_blocked_contacts_impl impl)
{
  klass->request_blocked_contacts_cb = impl;
}

void
tp_svc_connection_interface_contact_blocking_emit_blocked_contacts_changed (gpointer instance,
    GHashTable *arg_Blocked_Contacts,
    GHashTable *arg_Unblocked_Contacts)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING));
  g_signal_emit (instance,
      connection_interface_contact_blocking_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_BLOCKING_BlockedContactsChanged],
      0,
      arg_Blocked_Contacts,
      arg_Unblocked_Contacts);
}

static inline void
tp_svc_connection_interface_contact_blocking_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* ContactBlockingCapabilities */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_contact_blocking_get_type (),
      &_tp_svc_connection_interface_contact_blocking_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.ContactBlocking");
  properties[0].name = g_quark_from_static_string ("ContactBlockingCapabilities");
  properties[0].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_BLOCKING, &interface);

  connection_interface_contact_blocking_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_BLOCKING_BlockedContactsChanged] =
  g_signal_new ("blocked-contacts-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));

}
static void
tp_svc_connection_interface_contact_blocking_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_contact_blocking_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_contact_blocking_methods[] = {
  { (GCallback) tp_svc_connection_interface_contact_blocking_block_contacts, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_contact_blocking_unblock_contacts, g_cclosure_marshal_generic, 113 },
  { (GCallback) tp_svc_connection_interface_contact_blocking_request_blocked_contacts, g_cclosure_marshal_generic, 209 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_blocking_object_info = {
  0,
  _tp_svc_connection_interface_contact_blocking_methods,
  3,
"org.freedesktop.Telepathy.Connection.Interface.ContactBlocking\0BlockContacts\0A\0Contacts\0I\0au\0Report_Abusive\0I\0b\0\0org.freedesktop.Telepathy.Connection.Interface.ContactBlocking\0UnblockContacts\0A\0Contacts\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactBlocking\0RequestBlockedContacts\0A\0Contacts\0O\0F\0N\0a{us}\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.ContactBlocking\0BlockedContactsChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_capabilities_object_info;

struct _TpSvcConnectionInterfaceContactCapabilitiesClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_contact_capabilities_update_capabilities_impl update_capabilities_cb;
    tp_svc_connection_interface_contact_capabilities_get_contact_capabilities_impl get_contact_capabilities_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_ContactCapabilitiesChanged,
    N_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_SIGNALS
};
static guint connection_interface_contact_capabilities_signals[N_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_SIGNALS] = {0};

static void tp_svc_connection_interface_contact_capabilities_base_init (gpointer klass);

GType
tp_svc_connection_interface_contact_capabilities_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceContactCapabilitiesClass),
        tp_svc_connection_interface_contact_capabilities_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceContactCapabilities", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_contact_capabilities_update_capabilities (TpSvcConnectionInterfaceContactCapabilities *self,
    const GPtrArray *in_Handler_Capabilities,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_capabilities_update_capabilities_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_GET_CLASS (self)->update_capabilities_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handler_Capabilities,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_capabilities_implement_update_capabilities (TpSvcConnectionInterfaceContactCapabilitiesClass *klass, tp_svc_connection_interface_contact_capabilities_update_capabilities_impl impl)
{
  klass->update_capabilities_cb = impl;
}

static void
tp_svc_connection_interface_contact_capabilities_get_contact_capabilities (TpSvcConnectionInterfaceContactCapabilities *self,
    const GArray *in_Handles,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_capabilities_get_contact_capabilities_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_GET_CLASS (self)->get_contact_capabilities_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handles,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_capabilities_implement_get_contact_capabilities (TpSvcConnectionInterfaceContactCapabilitiesClass *klass, tp_svc_connection_interface_contact_capabilities_get_contact_capabilities_impl impl)
{
  klass->get_contact_capabilities_cb = impl;
}

void
tp_svc_connection_interface_contact_capabilities_emit_contact_capabilities_changed (gpointer instance,
    GHashTable *arg_caps)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_CAPABILITIES));
  g_signal_emit (instance,
      connection_interface_contact_capabilities_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_ContactCapabilitiesChanged],
      0,
      arg_caps);
}

static inline void
tp_svc_connection_interface_contact_capabilities_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_connection_interface_contact_capabilities_get_type (),
      &_tp_svc_connection_interface_contact_capabilities_object_info);

  connection_interface_contact_capabilities_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_ContactCapabilitiesChanged] =
  g_signal_new ("contact-capabilities-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_STRV, G_TYPE_INVALID)))))));

}
static void
tp_svc_connection_interface_contact_capabilities_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_contact_capabilities_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_contact_capabilities_methods[] = {
  { (GCallback) tp_svc_connection_interface_contact_capabilities_update_capabilities, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_contact_capabilities_get_contact_capabilities, g_cclosure_marshal_generic, 125 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_capabilities_object_info = {
  0,
  _tp_svc_connection_interface_contact_capabilities_methods,
  2,
"org.freedesktop.Telepathy.Connection.Interface.ContactCapabilities\0UpdateCapabilities\0A\0Handler_Capabilities\0I\0a(saa{sv}as)\0\0org.freedesktop.Telepathy.Connection.Interface.ContactCapabilities\0GetContactCapabilities\0A\0Handles\0I\0au\0Contact_Capabilities\0O\0F\0N\0a{ua(a{sv}as)}\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.ContactCapabilities\0ContactCapabilitiesChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_groups_object_info;

struct _TpSvcConnectionInterfaceContactGroupsClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_contact_groups_set_contact_groups_impl set_contact_groups_cb;
    tp_svc_connection_interface_contact_groups_set_group_members_impl set_group_members_cb;
    tp_svc_connection_interface_contact_groups_add_to_group_impl add_to_group_cb;
    tp_svc_connection_interface_contact_groups_remove_from_group_impl remove_from_group_cb;
    tp_svc_connection_interface_contact_groups_remove_group_impl remove_group_cb;
    tp_svc_connection_interface_contact_groups_rename_group_impl rename_group_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsChanged,
    SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsCreated,
    SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupRenamed,
    SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsRemoved,
    N_CONNECTION_INTERFACE_CONTACT_GROUPS_SIGNALS
};
static guint connection_interface_contact_groups_signals[N_CONNECTION_INTERFACE_CONTACT_GROUPS_SIGNALS] = {0};

static void tp_svc_connection_interface_contact_groups_base_init (gpointer klass);

GType
tp_svc_connection_interface_contact_groups_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceContactGroupsClass),
        tp_svc_connection_interface_contact_groups_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceContactGroups", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_contact_groups_set_contact_groups (TpSvcConnectionInterfaceContactGroups *self,
    guint in_Contact,
    const gchar **in_Groups,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_groups_set_contact_groups_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS_GET_CLASS (self)->set_contact_groups_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contact,
        in_Groups,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_groups_implement_set_contact_groups (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_set_contact_groups_impl impl)
{
  klass->set_contact_groups_cb = impl;
}

static void
tp_svc_connection_interface_contact_groups_set_group_members (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Group,
    const GArray *in_Members,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_groups_set_group_members_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS_GET_CLASS (self)->set_group_members_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Group,
        in_Members,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_groups_implement_set_group_members (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_set_group_members_impl impl)
{
  klass->set_group_members_cb = impl;
}

static void
tp_svc_connection_interface_contact_groups_add_to_group (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Group,
    const GArray *in_Members,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_groups_add_to_group_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS_GET_CLASS (self)->add_to_group_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Group,
        in_Members,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_groups_implement_add_to_group (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_add_to_group_impl impl)
{
  klass->add_to_group_cb = impl;
}

static void
tp_svc_connection_interface_contact_groups_remove_from_group (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Group,
    const GArray *in_Members,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_groups_remove_from_group_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS_GET_CLASS (self)->remove_from_group_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Group,
        in_Members,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_groups_implement_remove_from_group (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_remove_from_group_impl impl)
{
  klass->remove_from_group_cb = impl;
}

static void
tp_svc_connection_interface_contact_groups_remove_group (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Group,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_groups_remove_group_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS_GET_CLASS (self)->remove_group_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Group,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_groups_implement_remove_group (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_remove_group_impl impl)
{
  klass->remove_group_cb = impl;
}

static void
tp_svc_connection_interface_contact_groups_rename_group (TpSvcConnectionInterfaceContactGroups *self,
    const gchar *in_Old_Name,
    const gchar *in_New_Name,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_groups_rename_group_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS_GET_CLASS (self)->rename_group_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Old_Name,
        in_New_Name,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_groups_implement_rename_group (TpSvcConnectionInterfaceContactGroupsClass *klass, tp_svc_connection_interface_contact_groups_rename_group_impl impl)
{
  klass->rename_group_cb = impl;
}

void
tp_svc_connection_interface_contact_groups_emit_groups_changed (gpointer instance,
    const GArray *arg_Contact,
    const gchar **arg_Added,
    const gchar **arg_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS));
  g_signal_emit (instance,
      connection_interface_contact_groups_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsChanged],
      0,
      arg_Contact,
      arg_Added,
      arg_Removed);
}

void
tp_svc_connection_interface_contact_groups_emit_groups_created (gpointer instance,
    const gchar **arg_Names)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS));
  g_signal_emit (instance,
      connection_interface_contact_groups_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsCreated],
      0,
      arg_Names);
}

void
tp_svc_connection_interface_contact_groups_emit_group_renamed (gpointer instance,
    const gchar *arg_Old_Name,
    const gchar *arg_New_Name)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS));
  g_signal_emit (instance,
      connection_interface_contact_groups_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupRenamed],
      0,
      arg_Old_Name,
      arg_New_Name);
}

void
tp_svc_connection_interface_contact_groups_emit_groups_removed (gpointer instance,
    const gchar **arg_Names)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS));
  g_signal_emit (instance,
      connection_interface_contact_groups_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsRemoved],
      0,
      arg_Names);
}

static inline void
tp_svc_connection_interface_contact_groups_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* DisjointGroups */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* GroupStorage */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Groups */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_contact_groups_get_type (),
      &_tp_svc_connection_interface_contact_groups_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.ContactGroups");
  properties[0].name = g_quark_from_static_string ("DisjointGroups");
  properties[0].type = G_TYPE_BOOLEAN;
  properties[1].name = g_quark_from_static_string ("GroupStorage");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("Groups");
  properties[2].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_GROUPS, &interface);

  connection_interface_contact_groups_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsChanged] =
  g_signal_new ("groups-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      DBUS_TYPE_G_UINT_ARRAY,
      G_TYPE_STRV,
      G_TYPE_STRV);

  connection_interface_contact_groups_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsCreated] =
  g_signal_new ("groups-created",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRV);

  connection_interface_contact_groups_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupRenamed] =
  g_signal_new ("group-renamed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_STRING,
      G_TYPE_STRING);

  connection_interface_contact_groups_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_GROUPS_GroupsRemoved] =
  g_signal_new ("groups-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRV);

}
static void
tp_svc_connection_interface_contact_groups_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_contact_groups_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_contact_groups_methods[] = {
  { (GCallback) tp_svc_connection_interface_contact_groups_set_contact_groups, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_contact_groups_set_group_members, g_cclosure_marshal_generic, 105 },
  { (GCallback) tp_svc_connection_interface_contact_groups_add_to_group, g_cclosure_marshal_generic, 208 },
  { (GCallback) tp_svc_connection_interface_contact_groups_remove_from_group, g_cclosure_marshal_generic, 306 },
  { (GCallback) tp_svc_connection_interface_contact_groups_remove_group, g_cclosure_marshal_generic, 409 },
  { (GCallback) tp_svc_connection_interface_contact_groups_rename_group, g_cclosure_marshal_generic, 495 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_groups_object_info = {
  0,
  _tp_svc_connection_interface_contact_groups_methods,
  6,
"org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0SetContactGroups\0A\0Contact\0I\0u\0Groups\0I\0as\0\0org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0SetGroupMembers\0A\0Group\0I\0s\0Members\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0AddToGroup\0A\0Group\0I\0s\0Members\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0RemoveFromGroup\0A\0Group\0I\0s\0Members\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0RemoveGroup\0A\0Group\0I\0s\0\0org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0RenameGroup\0A\0Old_Name\0I\0s\0New_Name\0I\0s\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0GroupsChanged\0org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0GroupsCreated\0org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0GroupRenamed\0org.freedesktop.Telepathy.Connection.Interface.ContactGroups\0GroupsRemoved\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_info_object_info;

struct _TpSvcConnectionInterfaceContactInfoClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_contact_info_get_contact_info_impl get_contact_info_cb;
    tp_svc_connection_interface_contact_info_refresh_contact_info_impl refresh_contact_info_cb;
    tp_svc_connection_interface_contact_info_request_contact_info_impl request_contact_info_cb;
    tp_svc_connection_interface_contact_info_set_contact_info_impl set_contact_info_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_CONTACT_INFO_ContactInfoChanged,
    N_CONNECTION_INTERFACE_CONTACT_INFO_SIGNALS
};
static guint connection_interface_contact_info_signals[N_CONNECTION_INTERFACE_CONTACT_INFO_SIGNALS] = {0};

static void tp_svc_connection_interface_contact_info_base_init (gpointer klass);

GType
tp_svc_connection_interface_contact_info_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceContactInfoClass),
        tp_svc_connection_interface_contact_info_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceContactInfo", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_contact_info_get_contact_info (TpSvcConnectionInterfaceContactInfo *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_info_get_contact_info_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_INFO_GET_CLASS (self)->get_contact_info_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_info_implement_get_contact_info (TpSvcConnectionInterfaceContactInfoClass *klass, tp_svc_connection_interface_contact_info_get_contact_info_impl impl)
{
  klass->get_contact_info_cb = impl;
}

static void
tp_svc_connection_interface_contact_info_refresh_contact_info (TpSvcConnectionInterfaceContactInfo *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_info_refresh_contact_info_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_INFO_GET_CLASS (self)->refresh_contact_info_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_info_implement_refresh_contact_info (TpSvcConnectionInterfaceContactInfoClass *klass, tp_svc_connection_interface_contact_info_refresh_contact_info_impl impl)
{
  klass->refresh_contact_info_cb = impl;
}

static void
tp_svc_connection_interface_contact_info_request_contact_info (TpSvcConnectionInterfaceContactInfo *self,
    guint in_Contact,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_info_request_contact_info_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_INFO_GET_CLASS (self)->request_contact_info_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contact,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_info_implement_request_contact_info (TpSvcConnectionInterfaceContactInfoClass *klass, tp_svc_connection_interface_contact_info_request_contact_info_impl impl)
{
  klass->request_contact_info_cb = impl;
}

static void
tp_svc_connection_interface_contact_info_set_contact_info (TpSvcConnectionInterfaceContactInfo *self,
    const GPtrArray *in_ContactInfo,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_info_set_contact_info_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_INFO_GET_CLASS (self)->set_contact_info_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ContactInfo,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_info_implement_set_contact_info (TpSvcConnectionInterfaceContactInfoClass *klass, tp_svc_connection_interface_contact_info_set_contact_info_impl impl)
{
  klass->set_contact_info_cb = impl;
}

void
tp_svc_connection_interface_contact_info_emit_contact_info_changed (gpointer instance,
    guint arg_Contact,
    const GPtrArray *arg_ContactInfo)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_INFO));
  g_signal_emit (instance,
      connection_interface_contact_info_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_INFO_ContactInfoChanged],
      0,
      arg_Contact,
      arg_ContactInfo);
}

static inline void
tp_svc_connection_interface_contact_info_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* ContactInfoFlags */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(sasuu)", 0, NULL, NULL }, /* SupportedFields */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_contact_info_get_type (),
      &_tp_svc_connection_interface_contact_info_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.ContactInfo");
  properties[0].name = g_quark_from_static_string ("ContactInfoFlags");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("SupportedFields");
  properties[1].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID))));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_INFO, &interface);

  connection_interface_contact_info_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_INFO_ContactInfoChanged] =
  g_signal_new ("contact-info-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRV, G_TYPE_STRV, G_TYPE_INVALID)))));

}
static void
tp_svc_connection_interface_contact_info_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_contact_info_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_contact_info_methods[] = {
  { (GCallback) tp_svc_connection_interface_contact_info_get_contact_info, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_contact_info_refresh_contact_info, g_cclosure_marshal_generic, 122 },
  { (GCallback) tp_svc_connection_interface_contact_info_request_contact_info, g_cclosure_marshal_generic, 217 },
  { (GCallback) tp_svc_connection_interface_contact_info_set_contact_info, g_cclosure_marshal_generic, 338 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_info_object_info = {
  0,
  _tp_svc_connection_interface_contact_info_methods,
  4,
"org.freedesktop.Telepathy.Connection.Interface.ContactInfo\0GetContactInfo\0A\0Contacts\0I\0au\0ContactInfo\0O\0F\0N\0a{ua(sasas)}\0\0org.freedesktop.Telepathy.Connection.Interface.ContactInfo\0RefreshContactInfo\0A\0Contacts\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactInfo\0RequestContactInfo\0A\0Contact\0I\0u\0Contact_Info\0O\0F\0N\0a(sasas)\0\0org.freedesktop.Telepathy.Connection.Interface.ContactInfo\0SetContactInfo\0A\0ContactInfo\0I\0a(sasas)\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.ContactInfo\0ContactInfoChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_list_object_info;

struct _TpSvcConnectionInterfaceContactListClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_contact_list_get_contact_list_attributes_impl get_contact_list_attributes_cb;
    tp_svc_connection_interface_contact_list_request_subscription_impl request_subscription_cb;
    tp_svc_connection_interface_contact_list_authorize_publication_impl authorize_publication_cb;
    tp_svc_connection_interface_contact_list_remove_contacts_impl remove_contacts_cb;
    tp_svc_connection_interface_contact_list_unsubscribe_impl unsubscribe_cb;
    tp_svc_connection_interface_contact_list_unpublish_impl unpublish_cb;
    tp_svc_connection_interface_contact_list_download_impl download_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactListStateChanged,
    SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactsChangedWithID,
    SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactsChanged,
    N_CONNECTION_INTERFACE_CONTACT_LIST_SIGNALS
};
static guint connection_interface_contact_list_signals[N_CONNECTION_INTERFACE_CONTACT_LIST_SIGNALS] = {0};

static void tp_svc_connection_interface_contact_list_base_init (gpointer klass);

GType
tp_svc_connection_interface_contact_list_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceContactListClass),
        tp_svc_connection_interface_contact_list_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceContactList", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_contact_list_get_contact_list_attributes (TpSvcConnectionInterfaceContactList *self,
    const gchar **in_Interfaces,
    gboolean in_Hold,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_list_get_contact_list_attributes_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST_GET_CLASS (self)->get_contact_list_attributes_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Interfaces,
        in_Hold,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_list_implement_get_contact_list_attributes (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_get_contact_list_attributes_impl impl)
{
  klass->get_contact_list_attributes_cb = impl;
}

static void
tp_svc_connection_interface_contact_list_request_subscription (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_list_request_subscription_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST_GET_CLASS (self)->request_subscription_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_list_implement_request_subscription (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_request_subscription_impl impl)
{
  klass->request_subscription_cb = impl;
}

static void
tp_svc_connection_interface_contact_list_authorize_publication (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_list_authorize_publication_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST_GET_CLASS (self)->authorize_publication_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_list_implement_authorize_publication (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_authorize_publication_impl impl)
{
  klass->authorize_publication_cb = impl;
}

static void
tp_svc_connection_interface_contact_list_remove_contacts (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_list_remove_contacts_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST_GET_CLASS (self)->remove_contacts_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_list_implement_remove_contacts (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_remove_contacts_impl impl)
{
  klass->remove_contacts_cb = impl;
}

static void
tp_svc_connection_interface_contact_list_unsubscribe (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_list_unsubscribe_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST_GET_CLASS (self)->unsubscribe_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_list_implement_unsubscribe (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_unsubscribe_impl impl)
{
  klass->unsubscribe_cb = impl;
}

static void
tp_svc_connection_interface_contact_list_unpublish (TpSvcConnectionInterfaceContactList *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_list_unpublish_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST_GET_CLASS (self)->unpublish_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contact_list_implement_unpublish (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_unpublish_impl impl)
{
  klass->unpublish_cb = impl;
}

static void
tp_svc_connection_interface_contact_list_download (TpSvcConnectionInterfaceContactList *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contact_list_download_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACT_LIST_GET_CLASS (self)->download_cb);

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
tp_svc_connection_interface_contact_list_implement_download (TpSvcConnectionInterfaceContactListClass *klass, tp_svc_connection_interface_contact_list_download_impl impl)
{
  klass->download_cb = impl;
}

void
tp_svc_connection_interface_contact_list_emit_contact_list_state_changed (gpointer instance,
    guint arg_Contact_List_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_LIST));
  g_signal_emit (instance,
      connection_interface_contact_list_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactListStateChanged],
      0,
      arg_Contact_List_State);
}

void
tp_svc_connection_interface_contact_list_emit_contacts_changed_with_id (gpointer instance,
    GHashTable *arg_Changes,
    GHashTable *arg_Identifiers,
    GHashTable *arg_Removals)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_LIST));
  g_signal_emit (instance,
      connection_interface_contact_list_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactsChangedWithID],
      0,
      arg_Changes,
      arg_Identifiers,
      arg_Removals);
}

void
tp_svc_connection_interface_contact_list_emit_contacts_changed (gpointer instance,
    GHashTable *arg_Changes,
    const GArray *arg_Removals)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_LIST));
  g_signal_emit (instance,
      connection_interface_contact_list_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactsChanged],
      0,
      arg_Changes,
      arg_Removals);
}

static inline void
tp_svc_connection_interface_contact_list_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* ContactListState */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* ContactListPersists */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* CanChangeContactList */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* RequestUsesMessage */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* DownloadAtConnection */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_contact_list_get_type (),
      &_tp_svc_connection_interface_contact_list_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.ContactList");
  properties[0].name = g_quark_from_static_string ("ContactListState");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("ContactListPersists");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("CanChangeContactList");
  properties[2].type = G_TYPE_BOOLEAN;
  properties[3].name = g_quark_from_static_string ("RequestUsesMessage");
  properties[3].type = G_TYPE_BOOLEAN;
  properties[4].name = g_quark_from_static_string ("DownloadAtConnection");
  properties[4].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACT_LIST, &interface);

  connection_interface_contact_list_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactListStateChanged] =
  g_signal_new ("contact-list-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  connection_interface_contact_list_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactsChangedWithID] =
  g_signal_new ("contacts-changed-with-id",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)),
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, G_TYPE_STRING)));

  connection_interface_contact_list_signals[SIGNAL_CONNECTION_INTERFACE_CONTACT_LIST_ContactsChanged] =
  g_signal_new ("contacts-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))),
      DBUS_TYPE_G_UINT_ARRAY);

}
static void
tp_svc_connection_interface_contact_list_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_contact_list_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_contact_list_methods[] = {
  { (GCallback) tp_svc_connection_interface_contact_list_get_contact_list_attributes, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_contact_list_request_subscription, g_cclosure_marshal_generic, 139 },
  { (GCallback) tp_svc_connection_interface_contact_list_authorize_publication, g_cclosure_marshal_generic, 247 },
  { (GCallback) tp_svc_connection_interface_contact_list_remove_contacts, g_cclosure_marshal_generic, 344 },
  { (GCallback) tp_svc_connection_interface_contact_list_unsubscribe, g_cclosure_marshal_generic, 435 },
  { (GCallback) tp_svc_connection_interface_contact_list_unpublish, g_cclosure_marshal_generic, 523 },
  { (GCallback) tp_svc_connection_interface_contact_list_download, g_cclosure_marshal_generic, 609 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_contact_list_object_info = {
  0,
  _tp_svc_connection_interface_contact_list_methods,
  7,
"org.freedesktop.Telepathy.Connection.Interface.ContactList\0GetContactListAttributes\0A\0Interfaces\0I\0as\0Hold\0I\0b\0Attributes\0O\0F\0N\0a{ua{sv}}\0\0org.freedesktop.Telepathy.Connection.Interface.ContactList\0RequestSubscription\0A\0Contacts\0I\0au\0Message\0I\0s\0\0org.freedesktop.Telepathy.Connection.Interface.ContactList\0AuthorizePublication\0A\0Contacts\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactList\0RemoveContacts\0A\0Contacts\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactList\0Unsubscribe\0A\0Contacts\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactList\0Unpublish\0A\0Contacts\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.ContactList\0Download\0A\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.ContactList\0ContactListStateChanged\0org.freedesktop.Telepathy.Connection.Interface.ContactList\0ContactsChangedWithID\0org.freedesktop.Telepathy.Connection.Interface.ContactList\0ContactsChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_contacts_object_info;

struct _TpSvcConnectionInterfaceContactsClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_contacts_get_contact_attributes_impl get_contact_attributes_cb;
    tp_svc_connection_interface_contacts_get_contact_by_id_impl get_contact_by_id_cb;
};

static void tp_svc_connection_interface_contacts_base_init (gpointer klass);

GType
tp_svc_connection_interface_contacts_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceContactsClass),
        tp_svc_connection_interface_contacts_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceContacts", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_contacts_get_contact_attributes (TpSvcConnectionInterfaceContacts *self,
    const GArray *in_Handles,
    const gchar **in_Interfaces,
    gboolean in_Hold,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contacts_get_contact_attributes_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACTS_GET_CLASS (self)->get_contact_attributes_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Handles,
        in_Interfaces,
        in_Hold,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contacts_implement_get_contact_attributes (TpSvcConnectionInterfaceContactsClass *klass, tp_svc_connection_interface_contacts_get_contact_attributes_impl impl)
{
  klass->get_contact_attributes_cb = impl;
}

static void
tp_svc_connection_interface_contacts_get_contact_by_id (TpSvcConnectionInterfaceContacts *self,
    const gchar *in_Identifier,
    const gchar **in_Interfaces,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_contacts_get_contact_by_id_impl impl = (TP_SVC_CONNECTION_INTERFACE_CONTACTS_GET_CLASS (self)->get_contact_by_id_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Identifier,
        in_Interfaces,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_contacts_implement_get_contact_by_id (TpSvcConnectionInterfaceContactsClass *klass, tp_svc_connection_interface_contacts_get_contact_by_id_impl impl)
{
  klass->get_contact_by_id_cb = impl;
}

static inline void
tp_svc_connection_interface_contacts_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* ContactAttributeInterfaces */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_contacts_get_type (),
      &_tp_svc_connection_interface_contacts_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.Contacts");
  properties[0].name = g_quark_from_static_string ("ContactAttributeInterfaces");
  properties[0].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_CONTACTS, &interface);

}
static void
tp_svc_connection_interface_contacts_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_contacts_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_contacts_methods[] = {
  { (GCallback) tp_svc_connection_interface_contacts_get_contact_attributes, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_contacts_get_contact_by_id, g_cclosure_marshal_generic, 145 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_contacts_object_info = {
  0,
  _tp_svc_connection_interface_contacts_methods,
  2,
"org.freedesktop.Telepathy.Connection.Interface.Contacts\0GetContactAttributes\0A\0Handles\0I\0au\0Interfaces\0I\0as\0Hold\0I\0b\0Attributes\0O\0F\0N\0a{ua{sv}}\0\0org.freedesktop.Telepathy.Connection.Interface.Contacts\0GetContactByID\0A\0Identifier\0I\0s\0Interfaces\0I\0as\0Handle\0O\0F\0N\0u\0Attributes\0O\0F\0N\0a{sv}\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_location_object_info;

struct _TpSvcConnectionInterfaceLocationClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_location_get_locations_impl get_locations_cb;
    tp_svc_connection_interface_location_request_location_impl request_location_cb;
    tp_svc_connection_interface_location_set_location_impl set_location_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_LOCATION_LocationUpdated,
    N_CONNECTION_INTERFACE_LOCATION_SIGNALS
};
static guint connection_interface_location_signals[N_CONNECTION_INTERFACE_LOCATION_SIGNALS] = {0};

static void tp_svc_connection_interface_location_base_init (gpointer klass);

GType
tp_svc_connection_interface_location_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceLocationClass),
        tp_svc_connection_interface_location_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceLocation", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_location_get_locations (TpSvcConnectionInterfaceLocation *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_location_get_locations_impl impl = (TP_SVC_CONNECTION_INTERFACE_LOCATION_GET_CLASS (self)->get_locations_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_location_implement_get_locations (TpSvcConnectionInterfaceLocationClass *klass, tp_svc_connection_interface_location_get_locations_impl impl)
{
  klass->get_locations_cb = impl;
}

static void
tp_svc_connection_interface_location_request_location (TpSvcConnectionInterfaceLocation *self,
    guint in_Contact,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_location_request_location_impl impl = (TP_SVC_CONNECTION_INTERFACE_LOCATION_GET_CLASS (self)->request_location_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contact,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_location_implement_request_location (TpSvcConnectionInterfaceLocationClass *klass, tp_svc_connection_interface_location_request_location_impl impl)
{
  klass->request_location_cb = impl;
}

static void
tp_svc_connection_interface_location_set_location (TpSvcConnectionInterfaceLocation *self,
    GHashTable *in_Location,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_location_set_location_impl impl = (TP_SVC_CONNECTION_INTERFACE_LOCATION_GET_CLASS (self)->set_location_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Location,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_location_implement_set_location (TpSvcConnectionInterfaceLocationClass *klass, tp_svc_connection_interface_location_set_location_impl impl)
{
  klass->set_location_cb = impl;
}

void
tp_svc_connection_interface_location_emit_location_updated (gpointer instance,
    guint arg_Contact,
    GHashTable *arg_Location)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_LOCATION));
  g_signal_emit (instance,
      connection_interface_location_signals[SIGNAL_CONNECTION_INTERFACE_LOCATION_LocationUpdated],
      0,
      arg_Contact,
      arg_Location);
}

static inline void
tp_svc_connection_interface_location_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "au", 0, NULL, NULL }, /* LocationAccessControlTypes */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "(uv)", 0, NULL, NULL }, /* LocationAccessControl */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* SupportedLocationFeatures */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_location_get_type (),
      &_tp_svc_connection_interface_location_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.Location");
  properties[0].name = g_quark_from_static_string ("LocationAccessControlTypes");
  properties[0].type = DBUS_TYPE_G_UINT_ARRAY;
  properties[1].name = g_quark_from_static_string ("LocationAccessControl");
  properties[1].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_VALUE, G_TYPE_INVALID));
  properties[2].name = g_quark_from_static_string ("SupportedLocationFeatures");
  properties[2].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_LOCATION, &interface);

  connection_interface_location_signals[SIGNAL_CONNECTION_INTERFACE_LOCATION_LocationUpdated] =
  g_signal_new ("location-updated",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

}
static void
tp_svc_connection_interface_location_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_location_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_location_methods[] = {
  { (GCallback) tp_svc_connection_interface_location_get_locations, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_location_request_location, g_cclosure_marshal_generic, 112 },
  { (GCallback) tp_svc_connection_interface_location_set_location, g_cclosure_marshal_generic, 220 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_location_object_info = {
  0,
  _tp_svc_connection_interface_location_methods,
  3,
"org.freedesktop.Telepathy.Connection.Interface.Location\0GetLocations\0A\0Contacts\0I\0au\0Locations\0O\0F\0N\0a{ua{sv}}\0\0org.freedesktop.Telepathy.Connection.Interface.Location\0RequestLocation\0A\0Contact\0I\0u\0Location\0O\0F\0N\0a{sv}\0\0org.freedesktop.Telepathy.Connection.Interface.Location\0SetLocation\0A\0Location\0I\0a{sv}\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.Location\0LocationUpdated\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_mail_notification_object_info;

struct _TpSvcConnectionInterfaceMailNotificationClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_mail_notification_request_inbox_url_impl request_inbox_url_cb;
    tp_svc_connection_interface_mail_notification_request_mail_url_impl request_mail_url_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_MAIL_NOTIFICATION_MailsReceived,
    SIGNAL_CONNECTION_INTERFACE_MAIL_NOTIFICATION_UnreadMailsChanged,
    N_CONNECTION_INTERFACE_MAIL_NOTIFICATION_SIGNALS
};
static guint connection_interface_mail_notification_signals[N_CONNECTION_INTERFACE_MAIL_NOTIFICATION_SIGNALS] = {0};

static void tp_svc_connection_interface_mail_notification_base_init (gpointer klass);

GType
tp_svc_connection_interface_mail_notification_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceMailNotificationClass),
        tp_svc_connection_interface_mail_notification_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceMailNotification", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_mail_notification_request_inbox_url (TpSvcConnectionInterfaceMailNotification *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_mail_notification_request_inbox_url_impl impl = (TP_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION_GET_CLASS (self)->request_inbox_url_cb);

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
tp_svc_connection_interface_mail_notification_implement_request_inbox_url (TpSvcConnectionInterfaceMailNotificationClass *klass, tp_svc_connection_interface_mail_notification_request_inbox_url_impl impl)
{
  klass->request_inbox_url_cb = impl;
}

static void
tp_svc_connection_interface_mail_notification_request_mail_url (TpSvcConnectionInterfaceMailNotification *self,
    const gchar *in_ID,
    const GValue *in_URL_Data,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_mail_notification_request_mail_url_impl impl = (TP_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION_GET_CLASS (self)->request_mail_url_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_ID,
        in_URL_Data,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_mail_notification_implement_request_mail_url (TpSvcConnectionInterfaceMailNotificationClass *klass, tp_svc_connection_interface_mail_notification_request_mail_url_impl impl)
{
  klass->request_mail_url_cb = impl;
}

void
tp_svc_connection_interface_mail_notification_emit_mails_received (gpointer instance,
    const GPtrArray *arg_Mails)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION));
  g_signal_emit (instance,
      connection_interface_mail_notification_signals[SIGNAL_CONNECTION_INTERFACE_MAIL_NOTIFICATION_MailsReceived],
      0,
      arg_Mails);
}

void
tp_svc_connection_interface_mail_notification_emit_unread_mails_changed (gpointer instance,
    guint arg_Count,
    const GPtrArray *arg_Mails_Added,
    const gchar **arg_Mails_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION));
  g_signal_emit (instance,
      connection_interface_mail_notification_signals[SIGNAL_CONNECTION_INTERFACE_MAIL_NOTIFICATION_UnreadMailsChanged],
      0,
      arg_Count,
      arg_Mails_Added,
      arg_Mails_Removed);
}

static inline void
tp_svc_connection_interface_mail_notification_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[5] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MailNotificationFlags */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* UnreadMailCount */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aa{sv}", 0, NULL, NULL }, /* UnreadMails */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* MailAddress */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_mail_notification_get_type (),
      &_tp_svc_connection_interface_mail_notification_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.MailNotification");
  properties[0].name = g_quark_from_static_string ("MailNotificationFlags");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("UnreadMailCount");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("UnreadMails");
  properties[2].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  properties[3].name = g_quark_from_static_string ("MailAddress");
  properties[3].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_MAIL_NOTIFICATION, &interface);

  connection_interface_mail_notification_signals[SIGNAL_CONNECTION_INTERFACE_MAIL_NOTIFICATION_MailsReceived] =
  g_signal_new ("mails-received",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));

  connection_interface_mail_notification_signals[SIGNAL_CONNECTION_INTERFACE_MAIL_NOTIFICATION_UnreadMailsChanged] =
  g_signal_new ("unread-mails-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_UINT,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))),
      G_TYPE_STRV);

}
static void
tp_svc_connection_interface_mail_notification_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_mail_notification_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_mail_notification_methods[] = {
  { (GCallback) tp_svc_connection_interface_mail_notification_request_inbox_url, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_mail_notification_request_mail_url, g_cclosure_marshal_generic, 103 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_mail_notification_object_info = {
  0,
  _tp_svc_connection_interface_mail_notification_methods,
  2,
"org.freedesktop.Telepathy.Connection.Interface.MailNotification\0RequestInboxURL\0A\0URL\0O\0F\0N\0(sua(ss))\0\0org.freedesktop.Telepathy.Connection.Interface.MailNotification\0RequestMailURL\0A\0ID\0I\0s\0URL_Data\0I\0v\0URL\0O\0F\0N\0(sua(ss))\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.MailNotification\0MailsReceived\0org.freedesktop.Telepathy.Connection.Interface.MailNotification\0UnreadMailsChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_power_saving_object_info;

struct _TpSvcConnectionInterfacePowerSavingClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_power_saving_set_power_saving_impl set_power_saving_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_POWER_SAVING_PowerSavingChanged,
    N_CONNECTION_INTERFACE_POWER_SAVING_SIGNALS
};
static guint connection_interface_power_saving_signals[N_CONNECTION_INTERFACE_POWER_SAVING_SIGNALS] = {0};

static void tp_svc_connection_interface_power_saving_base_init (gpointer klass);

GType
tp_svc_connection_interface_power_saving_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfacePowerSavingClass),
        tp_svc_connection_interface_power_saving_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfacePowerSaving", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_power_saving_set_power_saving (TpSvcConnectionInterfacePowerSaving *self,
    gboolean in_Activate,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_power_saving_set_power_saving_impl impl = (TP_SVC_CONNECTION_INTERFACE_POWER_SAVING_GET_CLASS (self)->set_power_saving_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Activate,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_power_saving_implement_set_power_saving (TpSvcConnectionInterfacePowerSavingClass *klass, tp_svc_connection_interface_power_saving_set_power_saving_impl impl)
{
  klass->set_power_saving_cb = impl;
}

void
tp_svc_connection_interface_power_saving_emit_power_saving_changed (gpointer instance,
    gboolean arg_Active)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_POWER_SAVING));
  g_signal_emit (instance,
      connection_interface_power_saving_signals[SIGNAL_CONNECTION_INTERFACE_POWER_SAVING_PowerSavingChanged],
      0,
      arg_Active);
}

static inline void
tp_svc_connection_interface_power_saving_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* PowerSavingActive */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_power_saving_get_type (),
      &_tp_svc_connection_interface_power_saving_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.PowerSaving");
  properties[0].name = g_quark_from_static_string ("PowerSavingActive");
  properties[0].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_POWER_SAVING, &interface);

  connection_interface_power_saving_signals[SIGNAL_CONNECTION_INTERFACE_POWER_SAVING_PowerSavingChanged] =
  g_signal_new ("power-saving-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

}
static void
tp_svc_connection_interface_power_saving_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_power_saving_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_power_saving_methods[] = {
  { (GCallback) tp_svc_connection_interface_power_saving_set_power_saving, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_power_saving_object_info = {
  0,
  _tp_svc_connection_interface_power_saving_methods,
  1,
"org.freedesktop.Telepathy.Connection.Interface.PowerSaving\0SetPowerSaving\0A\0Activate\0I\0b\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.PowerSaving\0PowerSavingChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_presence_object_info;

struct _TpSvcConnectionInterfacePresenceClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_presence_add_status_impl add_status_cb;
    tp_svc_connection_interface_presence_clear_status_impl clear_status_cb;
    tp_svc_connection_interface_presence_get_presence_impl get_presence_cb;
    tp_svc_connection_interface_presence_get_statuses_impl get_statuses_cb;
    tp_svc_connection_interface_presence_remove_status_impl remove_status_cb;
    tp_svc_connection_interface_presence_request_presence_impl request_presence_cb;
    tp_svc_connection_interface_presence_set_last_activity_time_impl set_last_activity_time_cb;
    tp_svc_connection_interface_presence_set_status_impl set_status_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_PRESENCE_PresenceUpdate,
    N_CONNECTION_INTERFACE_PRESENCE_SIGNALS
};
static guint connection_interface_presence_signals[N_CONNECTION_INTERFACE_PRESENCE_SIGNALS] = {0};

static void tp_svc_connection_interface_presence_base_init (gpointer klass);

GType
tp_svc_connection_interface_presence_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfacePresenceClass),
        tp_svc_connection_interface_presence_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfacePresence", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_presence_add_status (TpSvcConnectionInterfacePresence *self,
    const gchar *in_Status,
    GHashTable *in_Parameters,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_presence_add_status_impl impl = (TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS (self)->add_status_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Status,
        in_Parameters,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_presence_implement_add_status (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_add_status_impl impl)
{
  klass->add_status_cb = impl;
}

static void
tp_svc_connection_interface_presence_clear_status (TpSvcConnectionInterfacePresence *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_presence_clear_status_impl impl = (TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS (self)->clear_status_cb);

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
tp_svc_connection_interface_presence_implement_clear_status (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_clear_status_impl impl)
{
  klass->clear_status_cb = impl;
}

static void
tp_svc_connection_interface_presence_get_presence (TpSvcConnectionInterfacePresence *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_presence_get_presence_impl impl = (TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS (self)->get_presence_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_presence_implement_get_presence (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_get_presence_impl impl)
{
  klass->get_presence_cb = impl;
}

static void
tp_svc_connection_interface_presence_get_statuses (TpSvcConnectionInterfacePresence *self,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_presence_get_statuses_impl impl = (TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS (self)->get_statuses_cb);

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
tp_svc_connection_interface_presence_implement_get_statuses (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_get_statuses_impl impl)
{
  klass->get_statuses_cb = impl;
}

static void
tp_svc_connection_interface_presence_remove_status (TpSvcConnectionInterfacePresence *self,
    const gchar *in_Status,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_presence_remove_status_impl impl = (TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS (self)->remove_status_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Status,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_presence_implement_remove_status (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_remove_status_impl impl)
{
  klass->remove_status_cb = impl;
}

static void
tp_svc_connection_interface_presence_request_presence (TpSvcConnectionInterfacePresence *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_presence_request_presence_impl impl = (TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS (self)->request_presence_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_presence_implement_request_presence (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_request_presence_impl impl)
{
  klass->request_presence_cb = impl;
}

static void
tp_svc_connection_interface_presence_set_last_activity_time (TpSvcConnectionInterfacePresence *self,
    guint in_Time,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_presence_set_last_activity_time_impl impl = (TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS (self)->set_last_activity_time_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Time,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_presence_implement_set_last_activity_time (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_set_last_activity_time_impl impl)
{
  klass->set_last_activity_time_cb = impl;
}

static void
tp_svc_connection_interface_presence_set_status (TpSvcConnectionInterfacePresence *self,
    GHashTable *in_Statuses,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_presence_set_status_impl impl = (TP_SVC_CONNECTION_INTERFACE_PRESENCE_GET_CLASS (self)->set_status_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Statuses,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_presence_implement_set_status (TpSvcConnectionInterfacePresenceClass *klass, tp_svc_connection_interface_presence_set_status_impl impl)
{
  klass->set_status_cb = impl;
}

void
tp_svc_connection_interface_presence_emit_presence_update (gpointer instance,
    GHashTable *arg_Presence)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_PRESENCE));
  g_signal_emit (instance,
      connection_interface_presence_signals[SIGNAL_CONNECTION_INTERFACE_PRESENCE_PresenceUpdate],
      0,
      arg_Presence);
}

static inline void
tp_svc_connection_interface_presence_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_connection_interface_presence_get_type (),
      &_tp_svc_connection_interface_presence_object_info);

  connection_interface_presence_signals[SIGNAL_CONNECTION_INTERFACE_PRESENCE_PresenceUpdate] =
  g_signal_new ("presence-update",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))), G_TYPE_INVALID)))));

}
static void
tp_svc_connection_interface_presence_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_presence_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_presence_methods[] = {
  { (GCallback) tp_svc_connection_interface_presence_add_status, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_presence_clear_status, g_cclosure_marshal_generic, 99 },
  { (GCallback) tp_svc_connection_interface_presence_get_presence, g_cclosure_marshal_generic, 170 },
  { (GCallback) tp_svc_connection_interface_presence_get_statuses, g_cclosure_marshal_generic, 287 },
  { (GCallback) tp_svc_connection_interface_presence_remove_status, g_cclosure_marshal_generic, 398 },
  { (GCallback) tp_svc_connection_interface_presence_request_presence, g_cclosure_marshal_generic, 481 },
  { (GCallback) tp_svc_connection_interface_presence_set_last_activity_time, g_cclosure_marshal_generic, 570 },
  { (GCallback) tp_svc_connection_interface_presence_set_status, g_cclosure_marshal_generic, 658 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_presence_object_info = {
  0,
  _tp_svc_connection_interface_presence_methods,
  8,
"org.freedesktop.Telepathy.Connection.Interface.Presence\0AddStatus\0A\0Status\0I\0s\0Parameters\0I\0a{sv}\0\0org.freedesktop.Telepathy.Connection.Interface.Presence\0ClearStatus\0A\0\0org.freedesktop.Telepathy.Connection.Interface.Presence\0GetPresence\0A\0Contacts\0I\0au\0Presence\0O\0F\0N\0a{u(ua{sa{sv}})}\0\0org.freedesktop.Telepathy.Connection.Interface.Presence\0GetStatuses\0A\0Available_Statuses\0O\0F\0N\0a{s(ubba{ss})}\0\0org.freedesktop.Telepathy.Connection.Interface.Presence\0RemoveStatus\0A\0Status\0I\0s\0\0org.freedesktop.Telepathy.Connection.Interface.Presence\0RequestPresence\0A\0Contacts\0I\0au\0\0org.freedesktop.Telepathy.Connection.Interface.Presence\0SetLastActivityTime\0A\0Time\0I\0u\0\0org.freedesktop.Telepathy.Connection.Interface.Presence\0SetStatus\0A\0Statuses\0I\0a{sa{sv}}\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.Presence\0PresenceUpdate\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_renaming_object_info;

struct _TpSvcConnectionInterfaceRenamingClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_renaming_request_rename_impl request_rename_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_RENAMING_Renamed,
    N_CONNECTION_INTERFACE_RENAMING_SIGNALS
};
static guint connection_interface_renaming_signals[N_CONNECTION_INTERFACE_RENAMING_SIGNALS] = {0};

static void tp_svc_connection_interface_renaming_base_init (gpointer klass);

GType
tp_svc_connection_interface_renaming_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceRenamingClass),
        tp_svc_connection_interface_renaming_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceRenaming", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_renaming_request_rename (TpSvcConnectionInterfaceRenaming *self,
    const gchar *in_Identifier,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_renaming_request_rename_impl impl = (TP_SVC_CONNECTION_INTERFACE_RENAMING_GET_CLASS (self)->request_rename_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Identifier,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_renaming_implement_request_rename (TpSvcConnectionInterfaceRenamingClass *klass, tp_svc_connection_interface_renaming_request_rename_impl impl)
{
  klass->request_rename_cb = impl;
}

void
tp_svc_connection_interface_renaming_emit_renamed (gpointer instance,
    guint arg_Original,
    guint arg_New)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_RENAMING));
  g_signal_emit (instance,
      connection_interface_renaming_signals[SIGNAL_CONNECTION_INTERFACE_RENAMING_Renamed],
      0,
      arg_Original,
      arg_New);
}

static inline void
tp_svc_connection_interface_renaming_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_connection_interface_renaming_get_type (),
      &_tp_svc_connection_interface_renaming_object_info);

  connection_interface_renaming_signals[SIGNAL_CONNECTION_INTERFACE_RENAMING_Renamed] =
  g_signal_new ("renamed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_connection_interface_renaming_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_renaming_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_renaming_methods[] = {
  { (GCallback) tp_svc_connection_interface_renaming_request_rename, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_renaming_object_info = {
  0,
  _tp_svc_connection_interface_renaming_methods,
  1,
"org.freedesktop.Telepathy.Connection.Interface.Renaming\0RequestRename\0A\0Identifier\0I\0s\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.Renaming\0Renamed\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_requests_object_info;

struct _TpSvcConnectionInterfaceRequestsClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_requests_create_channel_impl create_channel_cb;
    tp_svc_connection_interface_requests_ensure_channel_impl ensure_channel_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_REQUESTS_NewChannels,
    SIGNAL_CONNECTION_INTERFACE_REQUESTS_ChannelClosed,
    N_CONNECTION_INTERFACE_REQUESTS_SIGNALS
};
static guint connection_interface_requests_signals[N_CONNECTION_INTERFACE_REQUESTS_SIGNALS] = {0};

static void tp_svc_connection_interface_requests_base_init (gpointer klass);

GType
tp_svc_connection_interface_requests_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceRequestsClass),
        tp_svc_connection_interface_requests_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceRequests", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_requests_create_channel (TpSvcConnectionInterfaceRequests *self,
    GHashTable *in_Request,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_requests_create_channel_impl impl = (TP_SVC_CONNECTION_INTERFACE_REQUESTS_GET_CLASS (self)->create_channel_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Request,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_requests_implement_create_channel (TpSvcConnectionInterfaceRequestsClass *klass, tp_svc_connection_interface_requests_create_channel_impl impl)
{
  klass->create_channel_cb = impl;
}

static void
tp_svc_connection_interface_requests_ensure_channel (TpSvcConnectionInterfaceRequests *self,
    GHashTable *in_Request,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_requests_ensure_channel_impl impl = (TP_SVC_CONNECTION_INTERFACE_REQUESTS_GET_CLASS (self)->ensure_channel_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Request,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_requests_implement_ensure_channel (TpSvcConnectionInterfaceRequestsClass *klass, tp_svc_connection_interface_requests_ensure_channel_impl impl)
{
  klass->ensure_channel_cb = impl;
}

void
tp_svc_connection_interface_requests_emit_new_channels (gpointer instance,
    const GPtrArray *arg_Channels)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_REQUESTS));
  g_signal_emit (instance,
      connection_interface_requests_signals[SIGNAL_CONNECTION_INTERFACE_REQUESTS_NewChannels],
      0,
      arg_Channels);
}

void
tp_svc_connection_interface_requests_emit_channel_closed (gpointer instance,
    const gchar *arg_Removed)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_REQUESTS));
  g_signal_emit (instance,
      connection_interface_requests_signals[SIGNAL_CONNECTION_INTERFACE_REQUESTS_ChannelClosed],
      0,
      arg_Removed);
}

static inline void
tp_svc_connection_interface_requests_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(oa{sv})", 0, NULL, NULL }, /* Channels */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(a{sv}as)", 0, NULL, NULL }, /* RequestableChannelClasses */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_requests_get_type (),
      &_tp_svc_connection_interface_requests_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.Requests");
  properties[0].name = g_quark_from_static_string ("Channels");
  properties[0].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID))));
  properties[1].name = g_quark_from_static_string ("RequestableChannelClasses");
  properties[1].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_STRV, G_TYPE_INVALID))));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_REQUESTS, &interface);

  connection_interface_requests_signals[SIGNAL_CONNECTION_INTERFACE_REQUESTS_NewChannels] =
  g_signal_new ("new-channels",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))));

  connection_interface_requests_signals[SIGNAL_CONNECTION_INTERFACE_REQUESTS_ChannelClosed] =
  g_signal_new ("channel-closed",
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
tp_svc_connection_interface_requests_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_requests_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_requests_methods[] = {
  { (GCallback) tp_svc_connection_interface_requests_create_channel, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_requests_ensure_channel, g_cclosure_marshal_generic, 128 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_requests_object_info = {
  0,
  _tp_svc_connection_interface_requests_methods,
  2,
"org.freedesktop.Telepathy.Connection.Interface.Requests\0CreateChannel\0A\0Request\0I\0a{sv}\0Channel\0O\0F\0N\0o\0Properties\0O\0F\0N\0a{sv}\0\0org.freedesktop.Telepathy.Connection.Interface.Requests\0EnsureChannel\0A\0Request\0I\0a{sv}\0Yours\0O\0F\0N\0b\0Channel\0O\0F\0N\0o\0Properties\0O\0F\0N\0a{sv}\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.Requests\0NewChannels\0org.freedesktop.Telepathy.Connection.Interface.Requests\0ChannelClosed\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_service_point_object_info;

struct _TpSvcConnectionInterfaceServicePointClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_SERVICE_POINT_ServicePointsChanged,
    N_CONNECTION_INTERFACE_SERVICE_POINT_SIGNALS
};
static guint connection_interface_service_point_signals[N_CONNECTION_INTERFACE_SERVICE_POINT_SIGNALS] = {0};

static void tp_svc_connection_interface_service_point_base_init (gpointer klass);

GType
tp_svc_connection_interface_service_point_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceServicePointClass),
        tp_svc_connection_interface_service_point_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceServicePoint", &info, 0);
    }

  return type;
}

void
tp_svc_connection_interface_service_point_emit_service_points_changed (gpointer instance,
    const GPtrArray *arg_Service_Points)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_SERVICE_POINT));
  g_signal_emit (instance,
      connection_interface_service_point_signals[SIGNAL_CONNECTION_INTERFACE_SERVICE_POINT_ServicePointsChanged],
      0,
      arg_Service_Points);
}

static inline void
tp_svc_connection_interface_service_point_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a((us)as)", 0, NULL, NULL }, /* KnownServicePoints */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_service_point_get_type (),
      &_tp_svc_connection_interface_service_point_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.ServicePoint");
  properties[0].name = g_quark_from_static_string ("KnownServicePoints");
  properties[0].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)), G_TYPE_STRV, G_TYPE_INVALID))));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_SERVICE_POINT, &interface);

  connection_interface_service_point_signals[SIGNAL_CONNECTION_INTERFACE_SERVICE_POINT_ServicePointsChanged] =
  g_signal_new ("service-points-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)), G_TYPE_STRV, G_TYPE_INVALID)))));

}
static void
tp_svc_connection_interface_service_point_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_service_point_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_service_point_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_connection_interface_service_point_object_info = {
  0,
  _tp_svc_connection_interface_service_point_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Connection.Interface.ServicePoint\0ServicePointsChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_sidecars1_object_info;

struct _TpSvcConnectionInterfaceSidecars1Class {
    GTypeInterface parent_class;
    tp_svc_connection_interface_sidecars1_ensure_sidecar_impl ensure_sidecar_cb;
};

static void tp_svc_connection_interface_sidecars1_base_init (gpointer klass);

GType
tp_svc_connection_interface_sidecars1_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceSidecars1Class),
        tp_svc_connection_interface_sidecars1_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceSidecars1", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_sidecars1_ensure_sidecar (TpSvcConnectionInterfaceSidecars1 *self,
    const gchar *in_Main_Interface,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_sidecars1_ensure_sidecar_impl impl = (TP_SVC_CONNECTION_INTERFACE_SIDECARS1_GET_CLASS (self)->ensure_sidecar_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Main_Interface,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_sidecars1_implement_ensure_sidecar (TpSvcConnectionInterfaceSidecars1Class *klass, tp_svc_connection_interface_sidecars1_ensure_sidecar_impl impl)
{
  klass->ensure_sidecar_cb = impl;
}

static inline void
tp_svc_connection_interface_sidecars1_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_connection_interface_sidecars1_get_type (),
      &_tp_svc_connection_interface_sidecars1_object_info);

}
static void
tp_svc_connection_interface_sidecars1_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_sidecars1_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_sidecars1_methods[] = {
  { (GCallback) tp_svc_connection_interface_sidecars1_ensure_sidecar, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_sidecars1_object_info = {
  0,
  _tp_svc_connection_interface_sidecars1_methods,
  1,
"org.freedesktop.Telepathy.Connection.Interface.Sidecars1\0EnsureSidecar\0A\0Main_Interface\0I\0s\0Path\0O\0F\0N\0o\0Properties\0O\0F\0N\0a{sv}\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_connection_interface_simple_presence_object_info;

struct _TpSvcConnectionInterfaceSimplePresenceClass {
    GTypeInterface parent_class;
    tp_svc_connection_interface_simple_presence_set_presence_impl set_presence_cb;
    tp_svc_connection_interface_simple_presence_get_presences_impl get_presences_cb;
};

enum {
    SIGNAL_CONNECTION_INTERFACE_SIMPLE_PRESENCE_PresencesChanged,
    N_CONNECTION_INTERFACE_SIMPLE_PRESENCE_SIGNALS
};
static guint connection_interface_simple_presence_signals[N_CONNECTION_INTERFACE_SIMPLE_PRESENCE_SIGNALS] = {0};

static void tp_svc_connection_interface_simple_presence_base_init (gpointer klass);

GType
tp_svc_connection_interface_simple_presence_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcConnectionInterfaceSimplePresenceClass),
        tp_svc_connection_interface_simple_presence_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcConnectionInterfaceSimplePresence", &info, 0);
    }

  return type;
}

static void
tp_svc_connection_interface_simple_presence_set_presence (TpSvcConnectionInterfaceSimplePresence *self,
    const gchar *in_Status,
    const gchar *in_Status_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_simple_presence_set_presence_impl impl = (TP_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE_GET_CLASS (self)->set_presence_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Status,
        in_Status_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_simple_presence_implement_set_presence (TpSvcConnectionInterfaceSimplePresenceClass *klass, tp_svc_connection_interface_simple_presence_set_presence_impl impl)
{
  klass->set_presence_cb = impl;
}

static void
tp_svc_connection_interface_simple_presence_get_presences (TpSvcConnectionInterfaceSimplePresence *self,
    const GArray *in_Contacts,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_interface_simple_presence_get_presences_impl impl = (TP_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE_GET_CLASS (self)->get_presences_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contacts,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_connection_interface_simple_presence_implement_get_presences (TpSvcConnectionInterfaceSimplePresenceClass *klass, tp_svc_connection_interface_simple_presence_get_presences_impl impl)
{
  klass->get_presences_cb = impl;
}

void
tp_svc_connection_interface_simple_presence_emit_presences_changed (gpointer instance,
    GHashTable *arg_Presence)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE));
  g_signal_emit (instance,
      connection_interface_simple_presence_signals[SIGNAL_CONNECTION_INTERFACE_SIMPLE_PRESENCE_PresencesChanged],
      0,
      arg_Presence);
}

static inline void
tp_svc_connection_interface_simple_presence_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{s(ubb)}", 0, NULL, NULL }, /* Statuses */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MaximumStatusMessageLength */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_connection_interface_simple_presence_get_type (),
      &_tp_svc_connection_interface_simple_presence_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Connection.Interface.SimplePresence");
  properties[0].name = g_quark_from_static_string ("Statuses");
  properties[0].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_BOOLEAN, G_TYPE_BOOLEAN, G_TYPE_INVALID))));
  properties[1].name = g_quark_from_static_string ("MaximumStatusMessageLength");
  properties[1].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE, &interface);

  connection_interface_simple_presence_signals[SIGNAL_CONNECTION_INTERFACE_SIMPLE_PRESENCE_PresencesChanged] =
  g_signal_new ("presences-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))));

}
static void
tp_svc_connection_interface_simple_presence_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_connection_interface_simple_presence_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_connection_interface_simple_presence_methods[] = {
  { (GCallback) tp_svc_connection_interface_simple_presence_set_presence, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_connection_interface_simple_presence_get_presences, g_cclosure_marshal_generic, 107 },
};

static const DBusGObjectInfo _tp_svc_connection_interface_simple_presence_object_info = {
  0,
  _tp_svc_connection_interface_simple_presence_methods,
  2,
"org.freedesktop.Telepathy.Connection.Interface.SimplePresence\0SetPresence\0A\0Status\0I\0s\0Status_Message\0I\0s\0\0org.freedesktop.Telepathy.Connection.Interface.SimplePresence\0GetPresences\0A\0Contacts\0I\0au\0Presence\0O\0F\0N\0a{u(uss)}\0\0\0",
"org.freedesktop.Telepathy.Connection.Interface.SimplePresence\0PresencesChanged\0\0",
"\0\0",
};


