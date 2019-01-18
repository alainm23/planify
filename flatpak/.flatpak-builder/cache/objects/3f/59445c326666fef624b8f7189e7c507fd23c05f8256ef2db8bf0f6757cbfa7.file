#ifndef TP_GEN_TP_CLI_DEBUG_H_INCLUDED
#define TP_GEN_TP_CLI_DEBUG_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_debug_signal_callback_new_debug_message) (TpDebugClient *proxy,
    gdouble arg_time,
    const gchar *arg_domain,
    guint arg_level,
    const gchar *arg_message,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_debug_connect_to_new_debug_message (TpDebugClient *proxy,
    tp_cli_debug_signal_callback_new_debug_message callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_debug_callback_for_get_messages) (TpDebugClient *proxy,
    const GPtrArray *out_Messages,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_debug_call_get_messages (TpDebugClient *proxy,
    gint timeout_ms,
    tp_cli_debug_callback_for_get_messages callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_DEBUG_H_INCLUDED) */
