#include "_gen/tp-svc-tls-cert.h"

static const DBusGObjectInfo _tp_svc_authentication_tls_certificate_object_info;

struct _TpSvcAuthenticationTLSCertificateClass {
    GTypeInterface parent_class;
    tp_svc_authentication_tls_certificate_accept_impl accept_cb;
    tp_svc_authentication_tls_certificate_reject_impl reject_cb;
};

enum {
    SIGNAL_AUTHENTICATION_TLS_CERTIFICATE_Accepted,
    SIGNAL_AUTHENTICATION_TLS_CERTIFICATE_Rejected,
    N_AUTHENTICATION_TLS_CERTIFICATE_SIGNALS
};
static guint authentication_tls_certificate_signals[N_AUTHENTICATION_TLS_CERTIFICATE_SIGNALS] = {0};

static void tp_svc_authentication_tls_certificate_base_init (gpointer klass);

GType
tp_svc_authentication_tls_certificate_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcAuthenticationTLSCertificateClass),
        tp_svc_authentication_tls_certificate_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcAuthenticationTLSCertificate", &info, 0);
    }

  return type;
}

static void
tp_svc_authentication_tls_certificate_accept (TpSvcAuthenticationTLSCertificate *self,
    DBusGMethodInvocation *context)
{
  tp_svc_authentication_tls_certificate_accept_impl impl = (TP_SVC_AUTHENTICATION_TLS_CERTIFICATE_GET_CLASS (self)->accept_cb);

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
tp_svc_authentication_tls_certificate_implement_accept (TpSvcAuthenticationTLSCertificateClass *klass, tp_svc_authentication_tls_certificate_accept_impl impl)
{
  klass->accept_cb = impl;
}

static void
tp_svc_authentication_tls_certificate_reject (TpSvcAuthenticationTLSCertificate *self,
    const GPtrArray *in_Rejections,
    DBusGMethodInvocation *context)
{
  tp_svc_authentication_tls_certificate_reject_impl impl = (TP_SVC_AUTHENTICATION_TLS_CERTIFICATE_GET_CLASS (self)->reject_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Rejections,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_authentication_tls_certificate_implement_reject (TpSvcAuthenticationTLSCertificateClass *klass, tp_svc_authentication_tls_certificate_reject_impl impl)
{
  klass->reject_cb = impl;
}

void
tp_svc_authentication_tls_certificate_emit_accepted (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_AUTHENTICATION_TLS_CERTIFICATE));
  g_signal_emit (instance,
      authentication_tls_certificate_signals[SIGNAL_AUTHENTICATION_TLS_CERTIFICATE_Accepted],
      0);
}

void
tp_svc_authentication_tls_certificate_emit_rejected (gpointer instance,
    const GPtrArray *arg_Rejections)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_AUTHENTICATION_TLS_CERTIFICATE));
  g_signal_emit (instance,
      authentication_tls_certificate_signals[SIGNAL_AUTHENTICATION_TLS_CERTIFICATE_Rejected],
      0,
      arg_Rejections);
}

static inline void
tp_svc_authentication_tls_certificate_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[5] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* State */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(usa{sv})", 0, NULL, NULL }, /* Rejections */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* CertificateType */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aay", 0, NULL, NULL }, /* CertificateChainData */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_authentication_tls_certificate_get_type (),
      &_tp_svc_authentication_tls_certificate_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Authentication.TLSCertificate");
  properties[0].name = g_quark_from_static_string ("State");
  properties[0].type = G_TYPE_UINT;
  properties[1].name = g_quark_from_static_string ("Rejections");
  properties[1].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID))));
  properties[2].name = g_quark_from_static_string ("CertificateType");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("CertificateChainData");
  properties[3].type = (dbus_g_type_get_collection ("GPtrArray", dbus_g_type_get_collection ("GArray", G_TYPE_UCHAR)));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_AUTHENTICATION_TLS_CERTIFICATE, &interface);

  authentication_tls_certificate_signals[SIGNAL_AUTHENTICATION_TLS_CERTIFICATE_Accepted] =
  g_signal_new ("accepted",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  authentication_tls_certificate_signals[SIGNAL_AUTHENTICATION_TLS_CERTIFICATE_Rejected] =
  g_signal_new ("rejected",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID)))));

}
static void
tp_svc_authentication_tls_certificate_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_authentication_tls_certificate_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_authentication_tls_certificate_methods[] = {
  { (GCallback) tp_svc_authentication_tls_certificate_accept, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_authentication_tls_certificate_reject, g_cclosure_marshal_generic, 66 },
};

static const DBusGObjectInfo _tp_svc_authentication_tls_certificate_object_info = {
  0,
  _tp_svc_authentication_tls_certificate_methods,
  2,
"org.freedesktop.Telepathy.Authentication.TLSCertificate\0Accept\0A\0\0org.freedesktop.Telepathy.Authentication.TLSCertificate\0Reject\0A\0Rejections\0I\0a(usa{sv})\0\0\0",
"org.freedesktop.Telepathy.Authentication.TLSCertificate\0Accepted\0org.freedesktop.Telepathy.Authentication.TLSCertificate\0Rejected\0\0",
"\0\0",
};


