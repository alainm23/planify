#include "_gen/tp-svc-client.h"

static const DBusGObjectInfo _tp_svc_client_object_info;

struct _TpSvcClientClass {
    GTypeInterface parent_class;
};

static void tp_svc_client_base_init (gpointer klass);

GType
tp_svc_client_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcClientClass),
        tp_svc_client_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcClient", &info, 0);
    }

  return type;
}

static inline void
tp_svc_client_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_client_get_type (),
      &_tp_svc_client_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Client");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CLIENT, &interface);

}
static void
tp_svc_client_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_client_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_client_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_client_object_info = {
  0,
  _tp_svc_client_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_client_approver_object_info;

struct _TpSvcClientApproverClass {
    GTypeInterface parent_class;
    tp_svc_client_approver_add_dispatch_operation_impl add_dispatch_operation_cb;
};

static void tp_svc_client_approver_base_init (gpointer klass);

GType
tp_svc_client_approver_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcClientApproverClass),
        tp_svc_client_approver_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcClientApprover", &info, 0);
    }

  return type;
}

static void
tp_svc_client_approver_add_dispatch_operation (TpSvcClientApprover *self,
    const GPtrArray *in_Channels,
    const gchar *in_DispatchOperation,
    GHashTable *in_Properties,
    DBusGMethodInvocation *context)
{
  tp_svc_client_approver_add_dispatch_operation_impl impl = (TP_SVC_CLIENT_APPROVER_GET_CLASS (self)->add_dispatch_operation_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Channels,
        in_DispatchOperation,
        in_Properties,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_client_approver_implement_add_dispatch_operation (TpSvcClientApproverClass *klass, tp_svc_client_approver_add_dispatch_operation_impl impl)
{
  klass->add_dispatch_operation_cb = impl;
}

static inline void
tp_svc_client_approver_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aa{sv}", 0, NULL, NULL }, /* ApproverChannelFilter */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_client_approver_get_type (),
      &_tp_svc_client_approver_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Client.Approver");
  properties[0].name = g_quark_from_static_string ("ApproverChannelFilter");
  properties[0].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CLIENT_APPROVER, &interface);

}
static void
tp_svc_client_approver_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_client_approver_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_client_approver_methods[] = {
  { (GCallback) tp_svc_client_approver_add_dispatch_operation, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_client_approver_object_info = {
  0,
  _tp_svc_client_approver_methods,
  1,
"org.freedesktop.Telepathy.Client.Approver\0AddDispatchOperation\0A\0Channels\0I\0a(oa{sv})\0DispatchOperation\0I\0o\0Properties\0I\0a{sv}\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_client_handler_object_info;

struct _TpSvcClientHandlerClass {
    GTypeInterface parent_class;
    tp_svc_client_handler_handle_channels_impl handle_channels_cb;
};

static void tp_svc_client_handler_base_init (gpointer klass);

GType
tp_svc_client_handler_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcClientHandlerClass),
        tp_svc_client_handler_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcClientHandler", &info, 0);
    }

  return type;
}

static void
tp_svc_client_handler_handle_channels (TpSvcClientHandler *self,
    const gchar *in_Account,
    const gchar *in_Connection,
    const GPtrArray *in_Channels,
    const GPtrArray *in_Requests_Satisfied,
    guint64 in_User_Action_Time,
    GHashTable *in_Handler_Info,
    DBusGMethodInvocation *context)
{
  tp_svc_client_handler_handle_channels_impl impl = (TP_SVC_CLIENT_HANDLER_GET_CLASS (self)->handle_channels_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Account,
        in_Connection,
        in_Channels,
        in_Requests_Satisfied,
        in_User_Action_Time,
        in_Handler_Info,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_client_handler_implement_handle_channels (TpSvcClientHandlerClass *klass, tp_svc_client_handler_handle_channels_impl impl)
{
  klass->handle_channels_cb = impl;
}

static inline void
tp_svc_client_handler_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[5] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aa{sv}", 0, NULL, NULL }, /* HandlerChannelFilter */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* BypassApproval */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Capabilities */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "ao", 0, NULL, NULL }, /* HandledChannels */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_client_handler_get_type (),
      &_tp_svc_client_handler_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Client.Handler");
  properties[0].name = g_quark_from_static_string ("HandlerChannelFilter");
  properties[0].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  properties[1].name = g_quark_from_static_string ("BypassApproval");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("Capabilities");
  properties[2].type = G_TYPE_STRV;
  properties[3].name = g_quark_from_static_string ("HandledChannels");
  properties[3].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CLIENT_HANDLER, &interface);

}
static void
tp_svc_client_handler_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_client_handler_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_client_handler_methods[] = {
  { (GCallback) tp_svc_client_handler_handle_channels, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_client_handler_object_info = {
  0,
  _tp_svc_client_handler_methods,
  1,
"org.freedesktop.Telepathy.Client.Handler\0HandleChannels\0A\0Account\0I\0o\0Connection\0I\0o\0Channels\0I\0a(oa{sv})\0Requests_Satisfied\0I\0ao\0User_Action_Time\0I\0t\0Handler_Info\0I\0a{sv}\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_client_interface_requests_object_info;

struct _TpSvcClientInterfaceRequestsClass {
    GTypeInterface parent_class;
    tp_svc_client_interface_requests_add_request_impl add_request_cb;
    tp_svc_client_interface_requests_remove_request_impl remove_request_cb;
};

static void tp_svc_client_interface_requests_base_init (gpointer klass);

GType
tp_svc_client_interface_requests_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcClientInterfaceRequestsClass),
        tp_svc_client_interface_requests_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcClientInterfaceRequests", &info, 0);
    }

  return type;
}

static void
tp_svc_client_interface_requests_add_request (TpSvcClientInterfaceRequests *self,
    const gchar *in_Request,
    GHashTable *in_Properties,
    DBusGMethodInvocation *context)
{
  tp_svc_client_interface_requests_add_request_impl impl = (TP_SVC_CLIENT_INTERFACE_REQUESTS_GET_CLASS (self)->add_request_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Request,
        in_Properties,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_client_interface_requests_implement_add_request (TpSvcClientInterfaceRequestsClass *klass, tp_svc_client_interface_requests_add_request_impl impl)
{
  klass->add_request_cb = impl;
}

static void
tp_svc_client_interface_requests_remove_request (TpSvcClientInterfaceRequests *self,
    const gchar *in_Request,
    const gchar *in_Error,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_client_interface_requests_remove_request_impl impl = (TP_SVC_CLIENT_INTERFACE_REQUESTS_GET_CLASS (self)->remove_request_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Request,
        in_Error,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_client_interface_requests_implement_remove_request (TpSvcClientInterfaceRequestsClass *klass, tp_svc_client_interface_requests_remove_request_impl impl)
{
  klass->remove_request_cb = impl;
}

static inline void
tp_svc_client_interface_requests_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_client_interface_requests_get_type (),
      &_tp_svc_client_interface_requests_object_info);

}
static void
tp_svc_client_interface_requests_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_client_interface_requests_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_client_interface_requests_methods[] = {
  { (GCallback) tp_svc_client_interface_requests_add_request, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_client_interface_requests_remove_request, g_cclosure_marshal_generic, 97 },
};

static const DBusGObjectInfo _tp_svc_client_interface_requests_object_info = {
  0,
  _tp_svc_client_interface_requests_methods,
  2,
"org.freedesktop.Telepathy.Client.Interface.Requests\0AddRequest\0A\0Request\0I\0o\0Properties\0I\0a{sv}\0\0org.freedesktop.Telepathy.Client.Interface.Requests\0RemoveRequest\0A\0Request\0I\0o\0Error\0I\0s\0Message\0I\0s\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_client_observer_object_info;

struct _TpSvcClientObserverClass {
    GTypeInterface parent_class;
    tp_svc_client_observer_observe_channels_impl observe_channels_cb;
};

static void tp_svc_client_observer_base_init (gpointer klass);

GType
tp_svc_client_observer_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcClientObserverClass),
        tp_svc_client_observer_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcClientObserver", &info, 0);
    }

  return type;
}

static void
tp_svc_client_observer_observe_channels (TpSvcClientObserver *self,
    const gchar *in_Account,
    const gchar *in_Connection,
    const GPtrArray *in_Channels,
    const gchar *in_Dispatch_Operation,
    const GPtrArray *in_Requests_Satisfied,
    GHashTable *in_Observer_Info,
    DBusGMethodInvocation *context)
{
  tp_svc_client_observer_observe_channels_impl impl = (TP_SVC_CLIENT_OBSERVER_GET_CLASS (self)->observe_channels_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Account,
        in_Connection,
        in_Channels,
        in_Dispatch_Operation,
        in_Requests_Satisfied,
        in_Observer_Info,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_client_observer_implement_observe_channels (TpSvcClientObserverClass *klass, tp_svc_client_observer_observe_channels_impl impl)
{
  klass->observe_channels_cb = impl;
}

static inline void
tp_svc_client_observer_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[4] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aa{sv}", 0, NULL, NULL }, /* ObserverChannelFilter */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* Recover */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* DelayApprovers */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_client_observer_get_type (),
      &_tp_svc_client_observer_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Client.Observer");
  properties[0].name = g_quark_from_static_string ("ObserverChannelFilter");
  properties[0].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  properties[1].name = g_quark_from_static_string ("Recover");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("DelayApprovers");
  properties[2].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CLIENT_OBSERVER, &interface);

}
static void
tp_svc_client_observer_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_client_observer_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_client_observer_methods[] = {
  { (GCallback) tp_svc_client_observer_observe_channels, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_client_observer_object_info = {
  0,
  _tp_svc_client_observer_methods,
  1,
"org.freedesktop.Telepathy.Client.Observer\0ObserveChannels\0A\0Account\0I\0o\0Connection\0I\0o\0Channels\0I\0a(oa{sv})\0Dispatch_Operation\0I\0o\0Requests_Satisfied\0I\0ao\0Observer_Info\0I\0a{sv}\0\0\0",
"\0\0",
"\0\0",
};


