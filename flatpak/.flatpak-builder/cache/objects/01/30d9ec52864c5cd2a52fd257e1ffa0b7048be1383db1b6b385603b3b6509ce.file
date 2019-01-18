#include "_gen/tp-svc-call-content-media-description.h"

static const DBusGObjectInfo _tp_svc_call_content_media_description_object_info;

struct _TpSvcCallContentMediaDescriptionClass {
    GTypeInterface parent_class;
    tp_svc_call_content_media_description_accept_impl accept_cb;
    tp_svc_call_content_media_description_reject_impl reject_cb;
};

static void tp_svc_call_content_media_description_base_init (gpointer klass);

GType
tp_svc_call_content_media_description_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentMediaDescriptionClass),
        tp_svc_call_content_media_description_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContentMediaDescription", &info, 0);
    }

  return type;
}

static void
tp_svc_call_content_media_description_accept (TpSvcCallContentMediaDescription *self,
    GHashTable *in_Local_Media_Description,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_media_description_accept_impl impl = (TP_SVC_CALL_CONTENT_MEDIA_DESCRIPTION_GET_CLASS (self)->accept_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Local_Media_Description,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_media_description_implement_accept (TpSvcCallContentMediaDescriptionClass *klass, tp_svc_call_content_media_description_accept_impl impl)
{
  klass->accept_cb = impl;
}

static void
tp_svc_call_content_media_description_reject (TpSvcCallContentMediaDescription *self,
    const GValueArray *in_Reason,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_media_description_reject_impl impl = (TP_SVC_CALL_CONTENT_MEDIA_DESCRIPTION_GET_CLASS (self)->reject_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Reason,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_media_description_implement_reject (TpSvcCallContentMediaDescriptionClass *klass, tp_svc_call_content_media_description_reject_impl impl)
{
  klass->reject_cb = impl;
}

static inline void
tp_svc_call_content_media_description_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[7] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* FurtherNegotiationRequired */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* HasRemoteInformation */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(usuuba{ss})", 0, NULL, NULL }, /* Codecs */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* RemoteContact */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{uau}", 0, NULL, NULL }, /* SSRCs */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_media_description_get_type (),
      &_tp_svc_call_content_media_description_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content.MediaDescription");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("FurtherNegotiationRequired");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("HasRemoteInformation");
  properties[2].type = G_TYPE_BOOLEAN;
  properties[3].name = g_quark_from_static_string ("Codecs");
  properties[3].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_BOOLEAN, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID))));
  properties[4].name = g_quark_from_static_string ("RemoteContact");
  properties[4].type = G_TYPE_UINT;
  properties[5].name = g_quark_from_static_string ("SSRCs");
  properties[5].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, DBUS_TYPE_G_UINT_ARRAY));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT_MEDIA_DESCRIPTION, &interface);

}
static void
tp_svc_call_content_media_description_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_media_description_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_media_description_methods[] = {
  { (GCallback) tp_svc_call_content_media_description_accept, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_call_content_media_description_reject, g_cclosure_marshal_generic, 99 },
};

static const DBusGObjectInfo _tp_svc_call_content_media_description_object_info = {
  0,
  _tp_svc_call_content_media_description_methods,
  2,
"org.freedesktop.Telepathy.Call1.Content.MediaDescription\0Accept\0A\0Local_Media_Description\0I\0a{sv}\0\0org.freedesktop.Telepathy.Call1.Content.MediaDescription\0Reject\0A\0Reason\0I\0(uuss)\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_call_content_media_description_interface_rtcp_extended_reports_object_info;

struct _TpSvcCallContentMediaDescriptionInterfaceRTCPExtendedReportsClass {
    GTypeInterface parent_class;
};

static void tp_svc_call_content_media_description_interface_rtcp_extended_reports_base_init (gpointer klass);

GType
tp_svc_call_content_media_description_interface_rtcp_extended_reports_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentMediaDescriptionInterfaceRTCPExtendedReportsClass),
        tp_svc_call_content_media_description_interface_rtcp_extended_reports_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContentMediaDescriptionInterfaceRTCPExtendedReports", &info, 0);
    }

  return type;
}

static inline void
tp_svc_call_content_media_description_interface_rtcp_extended_reports_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[8] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* LossRLEMaxSize */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* DuplicateRLEMaxSize */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* PacketReceiptTimesMaxSize */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* DLRRMaxSize */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* RTTMode */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* StatisticsFlags */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* EnableMetrics */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_media_description_interface_rtcp_extended_reports_get_type (),
      &_tp_svc_call_content_media_description_interface_rtcp_extended_reports_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content.MediaDescription.Interface.RTCPExtendedReports");
  properties[0].name = g_quark_from_static_string ("LossRLEMaxSize");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("DuplicateRLEMaxSize");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("PacketReceiptTimesMaxSize");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("DLRRMaxSize");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("RTTMode");
  properties[4].type = G_TYPE_UINT;
  properties[5].name = g_quark_from_static_string ("StatisticsFlags");
  properties[5].type = G_TYPE_UINT;
  properties[6].name = g_quark_from_static_string ("EnableMetrics");
  properties[6].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_EXTENDED_REPORTS, &interface);

}
static void
tp_svc_call_content_media_description_interface_rtcp_extended_reports_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_media_description_interface_rtcp_extended_reports_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_media_description_interface_rtcp_extended_reports_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_call_content_media_description_interface_rtcp_extended_reports_object_info = {
  0,
  _tp_svc_call_content_media_description_interface_rtcp_extended_reports_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_call_content_media_description_interface_rtcp_feedback_object_info;

struct _TpSvcCallContentMediaDescriptionInterfaceRTCPFeedbackClass {
    GTypeInterface parent_class;
};

static void tp_svc_call_content_media_description_interface_rtcp_feedback_base_init (gpointer klass);

GType
tp_svc_call_content_media_description_interface_rtcp_feedback_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentMediaDescriptionInterfaceRTCPFeedbackClass),
        tp_svc_call_content_media_description_interface_rtcp_feedback_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContentMediaDescriptionInterfaceRTCPFeedback", &info, 0);
    }

  return type;
}

static inline void
tp_svc_call_content_media_description_interface_rtcp_feedback_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{u(ua(sss))}", 0, NULL, NULL }, /* FeedbackMessages */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* DoesAVPF */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_media_description_interface_rtcp_feedback_get_type (),
      &_tp_svc_call_content_media_description_interface_rtcp_feedback_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content.MediaDescription.Interface.RTCPFeedback");
  properties[0].name = g_quark_from_static_string ("FeedbackMessages");
  properties[0].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID))));
  properties[1].name = g_quark_from_static_string ("DoesAVPF");
  properties[1].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTCP_FEEDBACK, &interface);

}
static void
tp_svc_call_content_media_description_interface_rtcp_feedback_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_media_description_interface_rtcp_feedback_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_media_description_interface_rtcp_feedback_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_call_content_media_description_interface_rtcp_feedback_object_info = {
  0,
  _tp_svc_call_content_media_description_interface_rtcp_feedback_methods,
  0,
"\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_call_content_media_description_interface_rtp_header_extensions_object_info;

struct _TpSvcCallContentMediaDescriptionInterfaceRTPHeaderExtensionsClass {
    GTypeInterface parent_class;
};

static void tp_svc_call_content_media_description_interface_rtp_header_extensions_base_init (gpointer klass);

GType
tp_svc_call_content_media_description_interface_rtp_header_extensions_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentMediaDescriptionInterfaceRTPHeaderExtensionsClass),
        tp_svc_call_content_media_description_interface_rtp_header_extensions_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContentMediaDescriptionInterfaceRTPHeaderExtensions", &info, 0);
    }

  return type;
}

static inline void
tp_svc_call_content_media_description_interface_rtp_header_extensions_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[2] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(uuss)", 0, NULL, NULL }, /* HeaderExtensions */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_media_description_interface_rtp_header_extensions_get_type (),
      &_tp_svc_call_content_media_description_interface_rtp_header_extensions_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content.MediaDescription.Interface.RTPHeaderExtensions");
  properties[0].name = g_quark_from_static_string ("HeaderExtensions");
  properties[0].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID))));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT_MEDIA_DESCRIPTION_INTERFACE_RTP_HEADER_EXTENSIONS, &interface);

}
static void
tp_svc_call_content_media_description_interface_rtp_header_extensions_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_media_description_interface_rtp_header_extensions_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_media_description_interface_rtp_header_extensions_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_call_content_media_description_interface_rtp_header_extensions_object_info = {
  0,
  _tp_svc_call_content_media_description_interface_rtp_header_extensions_methods,
  0,
"\0",
"\0\0",
"\0\0",
};


