#include "_gen/tp-svc-generic.h"

static const DBusGObjectInfo _tp_svc_dbus_introspectable_object_info;

struct _TpSvcDBusIntrospectableClass {
    GTypeInterface parent_class;
    tp_svc_dbus_introspectable_introspect_impl introspect_cb;
};

static void tp_svc_dbus_introspectable_base_init (gpointer klass);

GType
tp_svc_dbus_introspectable_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcDBusIntrospectableClass),
        tp_svc_dbus_introspectable_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcDBusIntrospectable", &info, 0);
    }

  return type;
}

static void
tp_svc_dbus_introspectable_introspect (TpSvcDBusIntrospectable *self,
    DBusGMethodInvocation *context)
{
  tp_svc_dbus_introspectable_introspect_impl impl = (TP_SVC_DBUS_INTROSPECTABLE_GET_CLASS (self)->introspect_cb);

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
tp_svc_dbus_introspectable_implement_introspect (TpSvcDBusIntrospectableClass *klass, tp_svc_dbus_introspectable_introspect_impl impl)
{
  klass->introspect_cb = impl;
}

static inline void
tp_svc_dbus_introspectable_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_dbus_introspectable_get_type (),
      &_tp_svc_dbus_introspectable_object_info);

}
static void
tp_svc_dbus_introspectable_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_dbus_introspectable_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_dbus_introspectable_methods[] = {
  { (GCallback) tp_svc_dbus_introspectable_introspect, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_dbus_introspectable_object_info = {
  0,
  _tp_svc_dbus_introspectable_methods,
  1,
"org.freedesktop.DBus.Introspectable\0Introspect\0A\0XML_Data\0O\0F\0N\0s\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_dbus_properties_object_info;

struct _TpSvcDBusPropertiesClass {
    GTypeInterface parent_class;
    tp_svc_dbus_properties_get_impl get_cb;
    tp_svc_dbus_properties_set_impl set_cb;
    tp_svc_dbus_properties_get_all_impl get_all_cb;
};

enum {
    SIGNAL_DBUS_PROPERTIES_PropertiesChanged,
    N_DBUS_PROPERTIES_SIGNALS
};
static guint dbus_properties_signals[N_DBUS_PROPERTIES_SIGNALS] = {0};

static void tp_svc_dbus_properties_base_init (gpointer klass);

GType
tp_svc_dbus_properties_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcDBusPropertiesClass),
        tp_svc_dbus_properties_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcDBusProperties", &info, 0);
    }

  return type;
}

static void
tp_svc_dbus_properties_get (TpSvcDBusProperties *self,
    const gchar *in_Interface_Name,
    const gchar *in_Property_Name,
    DBusGMethodInvocation *context)
{
  tp_svc_dbus_properties_get_impl impl = (TP_SVC_DBUS_PROPERTIES_GET_CLASS (self)->get_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Interface_Name,
        in_Property_Name,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_dbus_properties_implement_get (TpSvcDBusPropertiesClass *klass, tp_svc_dbus_properties_get_impl impl)
{
  klass->get_cb = impl;
}

static void
tp_svc_dbus_properties_set (TpSvcDBusProperties *self,
    const gchar *in_Interface_Name,
    const gchar *in_Property_Name,
    const GValue *in_Value,
    DBusGMethodInvocation *context)
{
  tp_svc_dbus_properties_set_impl impl = (TP_SVC_DBUS_PROPERTIES_GET_CLASS (self)->set_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Interface_Name,
        in_Property_Name,
        in_Value,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_dbus_properties_implement_set (TpSvcDBusPropertiesClass *klass, tp_svc_dbus_properties_set_impl impl)
{
  klass->set_cb = impl;
}

static void
tp_svc_dbus_properties_get_all (TpSvcDBusProperties *self,
    const gchar *in_Interface_Name,
    DBusGMethodInvocation *context)
{
  tp_svc_dbus_properties_get_all_impl impl = (TP_SVC_DBUS_PROPERTIES_GET_CLASS (self)->get_all_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Interface_Name,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_dbus_properties_implement_get_all (TpSvcDBusPropertiesClass *klass, tp_svc_dbus_properties_get_all_impl impl)
{
  klass->get_all_cb = impl;
}

void
tp_svc_dbus_properties_emit_properties_changed (gpointer instance,
    const gchar *arg_Interface_Name,
    GHashTable *arg_Changed_Properties,
    const gchar **arg_Invalidated_Properties)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_DBUS_PROPERTIES));
  g_signal_emit (instance,
      dbus_properties_signals[SIGNAL_DBUS_PROPERTIES_PropertiesChanged],
      0,
      arg_Interface_Name,
      arg_Changed_Properties,
      arg_Invalidated_Properties);
}

static inline void
tp_svc_dbus_properties_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_dbus_properties_get_type (),
      &_tp_svc_dbus_properties_object_info);

  dbus_properties_signals[SIGNAL_DBUS_PROPERTIES_PropertiesChanged] =
  g_signal_new ("properties-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      3,
      G_TYPE_STRING,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)),
      G_TYPE_STRV);

}
static void
tp_svc_dbus_properties_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_dbus_properties_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_dbus_properties_methods[] = {
  { (GCallback) tp_svc_dbus_properties_get, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_dbus_properties_set, g_cclosure_marshal_generic, 90 },
  { (GCallback) tp_svc_dbus_properties_get_all, g_cclosure_marshal_generic, 176 },
};

static const DBusGObjectInfo _tp_svc_dbus_properties_object_info = {
  0,
  _tp_svc_dbus_properties_methods,
  3,
"org.freedesktop.DBus.Properties\0Get\0A\0Interface_Name\0I\0s\0Property_Name\0I\0s\0Value\0O\0F\0N\0v\0\0org.freedesktop.DBus.Properties\0Set\0A\0Interface_Name\0I\0s\0Property_Name\0I\0s\0Value\0I\0v\0\0org.freedesktop.DBus.Properties\0GetAll\0A\0Interface_Name\0I\0s\0Properties\0O\0F\0N\0a{sv}\0\0\0",
"org.freedesktop.DBus.Properties\0PropertiesChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_properties_interface_object_info;

struct _TpSvcPropertiesInterfaceClass {
    GTypeInterface parent_class;
    tp_svc_properties_interface_get_properties_impl get_properties_cb;
    tp_svc_properties_interface_list_properties_impl list_properties_cb;
    tp_svc_properties_interface_set_properties_impl set_properties_cb;
};

enum {
    SIGNAL_PROPERTIES_INTERFACE_PropertiesChanged,
    SIGNAL_PROPERTIES_INTERFACE_PropertyFlagsChanged,
    N_PROPERTIES_INTERFACE_SIGNALS
};
static guint properties_interface_signals[N_PROPERTIES_INTERFACE_SIGNALS] = {0};

static void tp_svc_properties_interface_base_init (gpointer klass);

GType
tp_svc_properties_interface_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcPropertiesInterfaceClass),
        tp_svc_properties_interface_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcPropertiesInterface", &info, 0);
    }

  return type;
}

static void
tp_svc_properties_interface_get_properties (TpSvcPropertiesInterface *self,
    const GArray *in_Properties,
    DBusGMethodInvocation *context)
{
  tp_svc_properties_interface_get_properties_impl impl = (TP_SVC_PROPERTIES_INTERFACE_GET_CLASS (self)->get_properties_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Properties,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_properties_interface_implement_get_properties (TpSvcPropertiesInterfaceClass *klass, tp_svc_properties_interface_get_properties_impl impl)
{
  klass->get_properties_cb = impl;
}

static void
tp_svc_properties_interface_list_properties (TpSvcPropertiesInterface *self,
    DBusGMethodInvocation *context)
{
  tp_svc_properties_interface_list_properties_impl impl = (TP_SVC_PROPERTIES_INTERFACE_GET_CLASS (self)->list_properties_cb);

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
tp_svc_properties_interface_implement_list_properties (TpSvcPropertiesInterfaceClass *klass, tp_svc_properties_interface_list_properties_impl impl)
{
  klass->list_properties_cb = impl;
}

static void
tp_svc_properties_interface_set_properties (TpSvcPropertiesInterface *self,
    const GPtrArray *in_Properties,
    DBusGMethodInvocation *context)
{
  tp_svc_properties_interface_set_properties_impl impl = (TP_SVC_PROPERTIES_INTERFACE_GET_CLASS (self)->set_properties_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Properties,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_properties_interface_implement_set_properties (TpSvcPropertiesInterfaceClass *klass, tp_svc_properties_interface_set_properties_impl impl)
{
  klass->set_properties_cb = impl;
}

void
tp_svc_properties_interface_emit_properties_changed (gpointer instance,
    const GPtrArray *arg_Properties)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_PROPERTIES_INTERFACE));
  g_signal_emit (instance,
      properties_interface_signals[SIGNAL_PROPERTIES_INTERFACE_PropertiesChanged],
      0,
      arg_Properties);
}

void
tp_svc_properties_interface_emit_property_flags_changed (gpointer instance,
    const GPtrArray *arg_Properties)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_PROPERTIES_INTERFACE));
  g_signal_emit (instance,
      properties_interface_signals[SIGNAL_PROPERTIES_INTERFACE_PropertyFlagsChanged],
      0,
      arg_Properties);
}

static inline void
tp_svc_properties_interface_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_properties_interface_get_type (),
      &_tp_svc_properties_interface_object_info);

  properties_interface_signals[SIGNAL_PROPERTIES_INTERFACE_PropertiesChanged] =
  g_signal_new ("properties-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_VALUE, G_TYPE_INVALID)))));

  properties_interface_signals[SIGNAL_PROPERTIES_INTERFACE_PropertyFlagsChanged] =
  g_signal_new ("property-flags-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)))));

}
static void
tp_svc_properties_interface_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_properties_interface_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_properties_interface_methods[] = {
  { (GCallback) tp_svc_properties_interface_get_properties, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_properties_interface_list_properties, g_cclosure_marshal_generic, 89 },
  { (GCallback) tp_svc_properties_interface_set_properties, g_cclosure_marshal_generic, 179 },
};

static const DBusGObjectInfo _tp_svc_properties_interface_object_info = {
  0,
  _tp_svc_properties_interface_methods,
  3,
"org.freedesktop.Telepathy.Properties\0GetProperties\0A\0Properties\0I\0au\0Values\0O\0F\0N\0a(uv)\0\0org.freedesktop.Telepathy.Properties\0ListProperties\0A\0Available_Properties\0O\0F\0N\0a(ussu)\0\0org.freedesktop.Telepathy.Properties\0SetProperties\0A\0Properties\0I\0a(uv)\0\0\0",
"org.freedesktop.Telepathy.Properties\0PropertiesChanged\0org.freedesktop.Telepathy.Properties\0PropertyFlagsChanged\0\0",
"\0\0",
};


