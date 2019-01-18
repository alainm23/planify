#ifndef TP_GEN_TP_CLI_MEDIA_SESSION_HANDLER_H_INCLUDED
#define TP_GEN_TP_CLI_MEDIA_SESSION_HANDLER_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_media_session_handler_signal_callback_new_stream_handler) (TpMediaSessionHandler *proxy,
    const gchar *arg_Stream_Handler,
    guint arg_ID,
    guint arg_Media_Type,
    guint arg_Direction,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_session_handler_connect_to_new_stream_handler (TpMediaSessionHandler *proxy,
    tp_cli_media_session_handler_signal_callback_new_stream_handler callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_session_handler_callback_for_error) (TpMediaSessionHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_session_handler_call_error (TpMediaSessionHandler *proxy,
    gint timeout_ms,
    guint in_Error_Code,
    const gchar *in_Message,
    tp_cli_media_session_handler_callback_for_error callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_session_handler_run_error (TpMediaSessionHandler *proxy,
    gint timeout_ms,
    guint in_Error_Code,
    const gchar *in_Message,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_session_handler_callback_for_ready) (TpMediaSessionHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_session_handler_call_ready (TpMediaSessionHandler *proxy,
    gint timeout_ms,
    tp_cli_media_session_handler_callback_for_ready callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_session_handler_run_ready (TpMediaSessionHandler *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_MEDIA_SESSION_HANDLER_H_INCLUDED) */
