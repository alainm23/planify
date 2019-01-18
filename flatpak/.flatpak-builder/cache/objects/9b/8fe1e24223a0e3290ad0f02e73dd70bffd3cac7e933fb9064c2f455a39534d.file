#include "_gen/tp-svc-account.h"

static const DBusGObjectInfo _tp_svc_account_object_info;

struct _TpSvcAccountClass {
    GTypeInterface parent_class;
    tp_svc_account_remove_impl remove_cb;
    tp_svc_account_update_parameters_impl update_parameters_cb;
    tp_svc_account_reconnect_impl reconnect_cb;
};

enum {
    SIGNAL_ACCOUNT_Removed,
    SIGNAL_ACCOUNT_AccountPropertyChanged,
    N_ACCOUNT_SIGNALS
};
static guint account_signals[N_ACCOUNT_SIGNALS] = {0};

static void tp_svc_account_base_init (gpointer klass);

GType
tp_svc_account_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcAccountClass),
        tp_svc_account_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcAccount", &info, 0);
    }

  return type;
}

static void
tp_svc_account_remove (TpSvcAccount *self,
    DBusGMethodInvocation *context)
{
  tp_svc_account_remove_impl impl = (TP_SVC_ACCOUNT_GET_CLASS (self)->remove_cb);

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
tp_svc_account_implement_remove (TpSvcAccountClass *klass, tp_svc_account_remove_impl impl)
{
  klass->remove_cb = impl;
}

static void
tp_svc_account_update_parameters (TpSvcAccount *self,
    GHashTable *in_Set,
    const gchar **in_Unset,
    DBusGMethodInvocation *context)
{
  tp_svc_account_update_parameters_impl impl = (TP_SVC_ACCOUNT_GET_CLASS (self)->update_parameters_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Set,
        in_Unset,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_account_implement_update_parameters (TpSvcAccountClass *klass, tp_svc_account_update_parameters_impl impl)
{
  klass->update_parameters_cb = impl;
}

static void
tp_svc_account_reconnect (TpSvcAccount *self,
    DBusGMethodInvocation *context)
{
  tp_svc_account_reconnect_impl impl = (TP_SVC_ACCOUNT_GET_CLASS (self)->reconnect_cb);

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
tp_svc_account_implement_reconnect (TpSvcAccountClass *klass, tp_svc_account_reconnect_impl impl)
{
  klass->reconnect_cb = impl;
}

void
tp_svc_account_emit_removed (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_ACCOUNT));
  g_signal_emit (instance,
      account_signals[SIGNAL_ACCOUNT_Removed],
      0);
}

void
tp_svc_account_emit_account_property_changed (gpointer instance,
    GHashTable *arg_Properties)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_ACCOUNT));
  g_signal_emit (instance,
      account_signals[SIGNAL_ACCOUNT_AccountPropertyChanged],
      0,
      arg_Properties);
}

static inline void
tp_svc_account_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[22] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "s", 0, NULL, NULL }, /* DisplayName */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "s", 0, NULL, NULL }, /* Icon */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* Valid */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "b", 0, NULL, NULL }, /* Enabled */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "s", 0, NULL, NULL }, /* Nickname */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "s", 0, NULL, NULL }, /* Service */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{sv}", 0, NULL, NULL }, /* Parameters */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "(uss)", 0, NULL, NULL }, /* AutomaticPresence */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "b", 0, NULL, NULL }, /* ConnectAutomatically */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "o", 0, NULL, NULL }, /* Connection */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* ConnectionStatus */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* ConnectionStatusReason */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* ConnectionError */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{sv}", 0, NULL, NULL }, /* ConnectionErrorDetails */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(uss)", 0, NULL, NULL }, /* CurrentPresence */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "(uss)", 0, NULL, NULL }, /* RequestedPresence */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* ChangingPresence */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* NormalizedName */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* HasBeenOnline */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "ao", 0, NULL, NULL }, /* Supersedes */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_account_get_type (),
      &_tp_svc_account_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Account");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("DisplayName");
  properties[1].type = G_TYPE_STRING;
  properties[2].name = g_quark_from_static_string ("Icon");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("Valid");
  properties[3].type = G_TYPE_BOOLEAN;
  properties[4].name = g_quark_from_static_string ("Enabled");
  properties[4].type = G_TYPE_BOOLEAN;
  properties[5].name = g_quark_from_static_string ("Nickname");
  properties[5].type = G_TYPE_STRING;
  properties[6].name = g_quark_from_static_string ("Service");
  properties[6].type = G_TYPE_STRING;
  properties[7].name = g_quark_from_static_string ("Parameters");
  properties[7].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE));
  properties[8].name = g_quark_from_static_string ("AutomaticPresence");
  properties[8].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID));
  properties[9].name = g_quark_from_static_string ("ConnectAutomatically");
  properties[9].type = G_TYPE_BOOLEAN;
  properties[10].name = g_quark_from_static_string ("Connection");
  properties[10].type = DBUS_TYPE_G_OBJECT_PATH;
  properties[11].name = g_quark_from_static_string ("ConnectionStatus");
  properties[11].type = G_TYPE_UINT;
  properties[12].name = g_quark_from_static_string ("ConnectionStatusReason");
  properties[12].type = G_TYPE_UINT;
  properties[13].name = g_quark_from_static_string ("ConnectionError");
  properties[13].type = G_TYPE_STRING;
  properties[14].name = g_quark_from_static_string ("ConnectionErrorDetails");
  properties[14].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE));
  properties[15].name = g_quark_from_static_string ("CurrentPresence");
  properties[15].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID));
  properties[16].name = g_quark_from_static_string ("RequestedPresence");
  properties[16].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID));
  properties[17].name = g_quark_from_static_string ("ChangingPresence");
  properties[17].type = G_TYPE_BOOLEAN;
  properties[18].name = g_quark_from_static_string ("NormalizedName");
  properties[18].type = G_TYPE_STRING;
  properties[19].name = g_quark_from_static_string ("HasBeenOnline");
  properties[19].type = G_TYPE_BOOLEAN;
  properties[20].name = g_quark_from_static_string ("Supersedes");
  properties[20].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_ACCOUNT, &interface);

  account_signals[SIGNAL_ACCOUNT_Removed] =
  g_signal_new ("removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  account_signals[SIGNAL_ACCOUNT_AccountPropertyChanged] =
  g_signal_new ("account-property-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

}
static void
tp_svc_account_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_account_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_account_methods[] = {
  { (GCallback) tp_svc_account_remove, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_account_update_parameters, g_cclosure_marshal_generic, 44 },
  { (GCallback) tp_svc_account_reconnect, g_cclosure_marshal_generic, 149 },
};

static const DBusGObjectInfo _tp_svc_account_object_info = {
  0,
  _tp_svc_account_methods,
  3,
"org.freedesktop.Telepathy.Account\0Remove\0A\0\0org.freedesktop.Telepathy.Account\0UpdateParameters\0A\0Set\0I\0a{sv}\0Unset\0I\0as\0Reconnect_Required\0O\0F\0N\0as\0\0org.freedesktop.Telepathy.Account\0Reconnect\0A\0\0\0",
"org.freedesktop.Telepathy.Account\0Removed\0org.freedesktop.Telepathy.Account\0AccountPropertyChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_account_interface_addressing_object_info;

struct _TpSvcAccountInterfaceAddressingClass {
    GTypeInterface parent_class;
    tp_svc_account_interface_addressing_set_uri_scheme_association_impl set_uri_scheme_association_cb;
};

static void tp_svc_account_interface_addressing_base_init (gpointer klass);

GType
tp_svc_account_interface_addressing_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcAccountInterfaceAddressingClass),
        tp_svc_account_interface_addressing_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcAccountInterfaceAddressing", &info, 0);
    }

  return type;
}

static void
tp_svc_account_interface_addressing_set_uri_scheme_association (TpSvcAccountInterfaceAddressing *self,
    const gchar *in_URI_Scheme,
    gboolean in_Association,
    DBusGMethodInvocation *context)
{
  tp_svc_account_interface_addressing_set_uri_scheme_association_impl impl = (TP_SVC_ACCOUNT_INTERFACE_ADDRESSING_GET_CLASS (self)->set_uri_scheme_association_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_URI_Scheme,
        in_Association,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_account_interface_addressing_implement_set_uri_scheme_association (TpSvcAccountInterfaceAddressingClass *klass, tp_svc_account_interface_addressing_set_uri_scheme_association_impl impl)
{
  klass->set_uri_scheme_association_cb = impl;
}

static inline void
tp_svc_account_interface_addressing_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "as", 0, NULL, NULL }, /* URISchemes */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_account_interface_addressing_get_type (),
      &_tp_svc_account_interface_addressing_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Account.Interface.Addressing");
  properties[0].name = g_quark_from_static_string ("URISchemes");
  properties[0].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_ACCOUNT_INTERFACE_ADDRESSING, &interface);

}
static void
tp_svc_account_interface_addressing_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_account_interface_addressing_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_account_interface_addressing_methods[] = {
  { (GCallback) tp_svc_account_interface_addressing_set_uri_scheme_association, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_account_interface_addressing_object_info = {
  0,
  _tp_svc_account_interface_addressing_methods,
  1,
"org.freedesktop.Telepathy.Account.Interface.Addressing\0SetURISchemeAssociation\0A\0URI_Scheme\0I\0s\0Association\0I\0b\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_account_interface_avatar_object_info;

struct _TpSvcAccountInterfaceAvatarClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_ACCOUNT_INTERFACE_AVATAR_AvatarChanged,
    N_ACCOUNT_INTERFACE_AVATAR_SIGNALS
};
static guint account_interface_avatar_signals[N_ACCOUNT_INTERFACE_AVATAR_SIGNALS] = {0};

static void tp_svc_account_interface_avatar_base_init (gpointer klass);

GType
tp_svc_account_interface_avatar_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcAccountInterfaceAvatarClass),
        tp_svc_account_interface_avatar_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcAccountInterfaceAvatar", &info, 0);
    }

  return type;
}

void
tp_svc_account_interface_avatar_emit_avatar_changed (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_ACCOUNT_INTERFACE_AVATAR));
  g_signal_emit (instance,
      account_interface_avatar_signals[SIGNAL_ACCOUNT_INTERFACE_AVATAR_AvatarChanged],
      0);
}

static inline void
tp_svc_account_interface_avatar_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE, "(ays)", 0, NULL, NULL }, /* Avatar */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_account_interface_avatar_get_type (),
      &_tp_svc_account_interface_avatar_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Account.Interface.Avatar");
  properties[0].name = g_quark_from_static_string ("Avatar");
  properties[0].type = (dbus_g_type_get_struct ("GValueArray", dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR), G_TYPE_STRING, G_TYPE_INVALID));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_ACCOUNT_INTERFACE_AVATAR, &interface);

  account_interface_avatar_signals[SIGNAL_ACCOUNT_INTERFACE_AVATAR_AvatarChanged] =
  g_signal_new ("avatar-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

}
static void
tp_svc_account_interface_avatar_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_account_interface_avatar_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_account_interface_avatar_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_account_interface_avatar_object_info = {
  0,
  _tp_svc_account_interface_avatar_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Account.Interface.Avatar\0AvatarChanged\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_account_interface_storage_object_info;

struct _TpSvcAccountInterfaceStorageClass {
    GTypeInterface parent_class;
};

static void tp_svc_account_interface_storage_base_init (gpointer klass);

GType
tp_svc_account_interface_storage_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcAccountInterfaceStorageClass),
        tp_svc_account_interface_storage_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcAccountInterfaceStorage", &info, 0);
    }

  return type;
}

static inline void
tp_svc_account_interface_storage_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[5] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* StorageProvider */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "v", 0, NULL, NULL }, /* StorageIdentifier */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{sv}", 0, NULL, NULL }, /* StorageSpecificInformation */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* StorageRestrictions */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_account_interface_storage_get_type (),
      &_tp_svc_account_interface_storage_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Account.Interface.Storage");
  properties[0].name = g_quark_from_static_string ("StorageProvider");
  properties[0].type = G_TYPE_STRING;
  properties[1].name = g_quark_from_static_string ("StorageIdentifier");
  properties[1].type = G_TYPE_VALUE;
  properties[2].name = g_quark_from_static_string ("StorageSpecificInformation");
  properties[2].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE));
  properties[3].name = g_quark_from_static_string ("StorageRestrictions");
  properties[3].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_ACCOUNT_INTERFACE_STORAGE, &interface);

}
static void
tp_svc_account_interface_storage_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_account_interface_storage_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_account_interface_storage_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_account_interface_storage_object_info = {
  0,
  _tp_svc_account_interface_storage_methods,
  0,
"\0",
"\0\0",
"\0\0",
};


