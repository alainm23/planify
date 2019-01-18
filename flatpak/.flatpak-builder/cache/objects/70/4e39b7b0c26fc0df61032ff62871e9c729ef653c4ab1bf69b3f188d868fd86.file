#ifndef TP_GEN_TP_CLI_TLS_CERT_H_INCLUDED
#define TP_GEN_TP_CLI_TLS_CERT_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_authentication_tls_certificate_signal_callback_accepted) (TpTLSCertificate *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_authentication_tls_certificate_connect_to_accepted (TpTLSCertificate *proxy,
    tp_cli_authentication_tls_certificate_signal_callback_accepted callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_authentication_tls_certificate_signal_callback_rejected) (TpTLSCertificate *proxy,
    const GPtrArray *arg_Rejections,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_authentication_tls_certificate_connect_to_rejected (TpTLSCertificate *proxy,
    tp_cli_authentication_tls_certificate_signal_callback_rejected callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_authentication_tls_certificate_callback_for_accept) (TpTLSCertificate *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_authentication_tls_certificate_call_accept (TpTLSCertificate *proxy,
    gint timeout_ms,
    tp_cli_authentication_tls_certificate_callback_for_accept callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_authentication_tls_certificate_callback_for_reject) (TpTLSCertificate *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_authentication_tls_certificate_call_reject (TpTLSCertificate *proxy,
    gint timeout_ms,
    const GPtrArray *in_Rejections,
    tp_cli_authentication_tls_certificate_callback_for_reject callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_TLS_CERT_H_INCLUDED) */
