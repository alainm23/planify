#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcAuthenticationTLSCertificate TpSvcAuthenticationTLSCertificate;

typedef struct _TpSvcAuthenticationTLSCertificateClass TpSvcAuthenticationTLSCertificateClass;

GType tp_svc_authentication_tls_certificate_get_type (void);
#define TP_TYPE_SVC_AUTHENTICATION_TLS_CERTIFICATE \
  (tp_svc_authentication_tls_certificate_get_type ())
#define TP_SVC_AUTHENTICATION_TLS_CERTIFICATE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_AUTHENTICATION_TLS_CERTIFICATE, TpSvcAuthenticationTLSCertificate))
#define TP_IS_SVC_AUTHENTICATION_TLS_CERTIFICATE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_AUTHENTICATION_TLS_CERTIFICATE))
#define TP_SVC_AUTHENTICATION_TLS_CERTIFICATE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_AUTHENTICATION_TLS_CERTIFICATE, TpSvcAuthenticationTLSCertificateClass))


typedef void (*tp_svc_authentication_tls_certificate_accept_impl) (TpSvcAuthenticationTLSCertificate *self,
    DBusGMethodInvocation *context);
void tp_svc_authentication_tls_certificate_implement_accept (TpSvcAuthenticationTLSCertificateClass *klass, tp_svc_authentication_tls_certificate_accept_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_authentication_tls_certificate_return_from_accept (DBusGMethodInvocation *context);
static inline void
tp_svc_authentication_tls_certificate_return_from_accept (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_authentication_tls_certificate_reject_impl) (TpSvcAuthenticationTLSCertificate *self,
    const GPtrArray *in_Rejections,
    DBusGMethodInvocation *context);
void tp_svc_authentication_tls_certificate_implement_reject (TpSvcAuthenticationTLSCertificateClass *klass, tp_svc_authentication_tls_certificate_reject_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_authentication_tls_certificate_return_from_reject (DBusGMethodInvocation *context);
static inline void
tp_svc_authentication_tls_certificate_return_from_reject (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_authentication_tls_certificate_emit_accepted (gpointer instance);
void tp_svc_authentication_tls_certificate_emit_rejected (gpointer instance,
    const GPtrArray *arg_Rejections);


G_END_DECLS
