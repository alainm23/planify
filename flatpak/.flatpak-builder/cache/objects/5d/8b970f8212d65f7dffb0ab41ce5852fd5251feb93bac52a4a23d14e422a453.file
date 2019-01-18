#include "_gen/tp-svc-protocol.h"

static const DBusGObjectInfo _tp_svc_protocol_object_info;

struct _TpSvcProtocolClass {
    GTypeInterface parent_class;
    tp_svc_protocol_identify_account_impl identify_account_cb;
    tp_svc_protocol_normalize_contact_impl normalize_contact_cb;
};

static void tp_svc_protocol_base_init (gpointer klass);

GType
tp_svc_protocol_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcProtocolClass),
        tp_svc_protocol_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcProtocol", &info, 0);
    }

  return type;
}

static void
tp_svc_protocol_identify_account (TpSvcProtocol *self,
    GHashTable *in_Parameters,
    DBusGMethodInvocation *context)
{
  tp_svc_protocol_identify_account_impl impl = (TP_SVC_PROTOCOL_GET_CLASS (self)->identify_account_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Parameters,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_protocol_implement_identify_account (TpSvcProtocolClass *klass, tp_svc_protocol_identify_account_impl impl)
{
  klass->identify_account_cb = impl;
}

static void
tp_svc_protocol_normalize_contact (TpSvcProtocol *self,
    const gchar *in_Contact_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_protocol_normalize_contact_impl impl = (TP_SVC_PROTOCOL_GET_CLASS (self)->normalize_contact_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Contact_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_protocol_implement_normalize_contact (TpSvcProtocolClass *klass, tp_svc_protocol_normalize_contact_impl impl)
{
  klass->normalize_contact_cb = impl;
}

static inline void
tp_svc_protocol_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[9] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(susv)", 0, NULL, NULL }, /* Parameters */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* ConnectionInterfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(a{sv}as)", 0, NULL, NULL }, /* RequestableChannelClasses */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* VCardField */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* EnglishName */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Icon */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* AuthenticationTypes */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_protocol_get_type (),
      &_tp_svc_protocol_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Protocol");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("Parameters");
  properties[1].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_VALUE, G_TYPE_INVALID))));
  properties[2].name = g_quark_from_static_string ("ConnectionInterfaces");
  properties[2].type = G_TYPE_STRV;
  properties[3].name = g_quark_from_static_string ("RequestableChannelClasses");
  properties[3].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_STRV, G_TYPE_INVALID))));
  properties[4].name = g_quark_from_static_string ("VCardField");
  properties[4].type = G_TYPE_STRING;
  properties[5].name = g_quark_from_static_string ("EnglishName");
  properties[5].type = G_TYPE_STRING;
  properties[6].name = g_quark_from_static_string ("Icon");
  properties[6].type = G_TYPE_STRING;
  properties[7].name = g_quark_from_static_string ("AuthenticationTypes");
  properties[7].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_PROTOCOL, &interface);

}
static void
tp_svc_protocol_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_protocol_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_protocol_methods[] = {
  { (GCallback) tp_svc_protocol_identify_account, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_protocol_normalize_contact, g_cclosure_marshal_generic, 92 },
};

static const DBusGObjectInfo _tp_svc_protocol_object_info = {
  0,
  _tp_svc_protocol_methods,
  2,
"org.freedesktop.Telepathy.Protocol\0IdentifyAccount\0A\0Parameters\0I\0a{sv}\0Account_ID\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Protocol\0NormalizeContact\0A\0Contact_ID\0I\0s\0Normalized_Contact_ID\0O\0F\0N\0s\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_protocol_interface_addressing_object_info;

struct _TpSvcProtocolInterfaceAddressingClass {
    GTypeInterface parent_class;
    tp_svc_protocol_interface_addressing_normalize_vcard_address_impl normalize_vcard_address_cb;
    tp_svc_protocol_interface_addressing_normalize_contact_uri_impl normalize_contact_uri_cb;
};

static void tp_svc_protocol_interface_addressing_base_init (gpointer klass);

GType
tp_svc_protocol_interface_addressing_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcProtocolInterfaceAddressingClass),
        tp_svc_protocol_interface_addressing_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcProtocolInterfaceAddressing", &info, 0);
    }

  return type;
}

static void
tp_svc_protocol_interface_addressing_normalize_vcard_address (TpSvcProtocolInterfaceAddressing *self,
    const gchar *in_VCard_Field,
    const gchar *in_VCard_Address,
    DBusGMethodInvocation *context)
{
  tp_svc_protocol_interface_addressing_normalize_vcard_address_impl impl = (TP_SVC_PROTOCOL_INTERFACE_ADDRESSING_GET_CLASS (self)->normalize_vcard_address_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_VCard_Field,
        in_VCard_Address,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_protocol_interface_addressing_implement_normalize_vcard_address (TpSvcProtocolInterfaceAddressingClass *klass, tp_svc_protocol_interface_addressing_normalize_vcard_address_impl impl)
{
  klass->normalize_vcard_address_cb = impl;
}

static void
tp_svc_protocol_interface_addressing_normalize_contact_uri (TpSvcProtocolInterfaceAddressing *self,
    const gchar *in_URI,
    DBusGMethodInvocation *context)
{
  tp_svc_protocol_interface_addressing_normalize_contact_uri_impl impl = (TP_SVC_PROTOCOL_INTERFACE_ADDRESSING_GET_CLASS (self)->normalize_contact_uri_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_URI,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_protocol_interface_addressing_implement_normalize_contact_uri (TpSvcProtocolInterfaceAddressingClass *klass, tp_svc_protocol_interface_addressing_normalize_contact_uri_impl impl)
{
  klass->normalize_contact_uri_cb = impl;
}

static inline void
tp_svc_protocol_interface_addressing_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* AddressableVCardFields */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* AddressableURISchemes */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_protocol_interface_addressing_get_type (),
      &_tp_svc_protocol_interface_addressing_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Protocol.Interface.Addressing");
  properties[0].name = g_quark_from_static_string ("AddressableVCardFields");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("AddressableURISchemes");
  properties[1].type = G_TYPE_STRV;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_PROTOCOL_INTERFACE_ADDRESSING, &interface);

}
static void
tp_svc_protocol_interface_addressing_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_protocol_interface_addressing_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_protocol_interface_addressing_methods[] = {
  { (GCallback) tp_svc_protocol_interface_addressing_normalize_vcard_address, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_protocol_interface_addressing_normalize_contact_uri, g_cclosure_marshal_generic, 148 },
};

static const DBusGObjectInfo _tp_svc_protocol_interface_addressing_object_info = {
  0,
  _tp_svc_protocol_interface_addressing_methods,
  2,
"org.freedesktop.Telepathy.Protocol.Interface.Addressing\0NormalizeVCardAddress\0A\0VCard_Field\0I\0s\0VCard_Address\0I\0s\0Normalized_VCard_Address\0O\0F\0N\0s\0\0org.freedesktop.Telepathy.Protocol.Interface.Addressing\0NormalizeContactURI\0A\0URI\0I\0s\0Normalized_URI\0O\0F\0N\0s\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_protocol_interface_avatars_object_info;

struct _TpSvcProtocolInterfaceAvatarsClass {
    GTypeInterface parent_class;
};

static void tp_svc_protocol_interface_avatars_base_init (gpointer klass);

GType
tp_svc_protocol_interface_avatars_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcProtocolInterfaceAvatarsClass),
        tp_svc_protocol_interface_avatars_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcProtocolInterfaceAvatars", &info, 0);
    }

  return type;
}

static inline void
tp_svc_protocol_interface_avatars_base_init_once (gpointer klass G_GNUC_UNUSED)
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

  dbus_g_object_type_install_info (tp_svc_protocol_interface_avatars_get_type (),
      &_tp_svc_protocol_interface_avatars_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Protocol.Interface.Avatars");
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
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_PROTOCOL_INTERFACE_AVATARS, &interface);

}
static void
tp_svc_protocol_interface_avatars_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_protocol_interface_avatars_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_protocol_interface_avatars_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_protocol_interface_avatars_object_info = {
  0,
  _tp_svc_protocol_interface_avatars_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_protocol_interface_presence_object_info;

struct _TpSvcProtocolInterfacePresenceClass {
    GTypeInterface parent_class;
};

static void tp_svc_protocol_interface_presence_base_init (gpointer klass);

GType
tp_svc_protocol_interface_presence_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcProtocolInterfacePresenceClass),
        tp_svc_protocol_interface_presence_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcProtocolInterfacePresence", &info, 0);
    }

  return type;
}

static inline void
tp_svc_protocol_interface_presence_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{s(ubb)}", 0, NULL, NULL }, /* Statuses */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_protocol_interface_presence_get_type (),
      &_tp_svc_protocol_interface_presence_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Protocol.Interface.Presence");
  properties[0].name = g_quark_from_static_string ("Statuses");
  properties[0].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_BOOLEAN, G_TYPE_BOOLEAN, G_TYPE_INVALID))));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_PROTOCOL_INTERFACE_PRESENCE, &interface);

}
static void
tp_svc_protocol_interface_presence_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_protocol_interface_presence_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_protocol_interface_presence_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_protocol_interface_presence_object_info = {
  0,
  _tp_svc_protocol_interface_presence_methods,
  0,
"\0",
"\0\0",
"\0\0",
};


