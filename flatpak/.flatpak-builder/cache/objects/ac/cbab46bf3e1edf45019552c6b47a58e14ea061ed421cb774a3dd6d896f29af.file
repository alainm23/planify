#ifndef TP_GEN_TP_CLI_CONNECTION_MANAGER_H_INCLUDED
#define TP_GEN_TP_CLI_CONNECTION_MANAGER_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_connection_manager_signal_callback_new_connection) (TpConnectionManager *proxy,
    const gchar *arg_Bus_Name,
    const gchar *arg_Object_Path,
    const gchar *arg_Protocol,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_connection_manager_connect_to_new_connection (TpConnectionManager *proxy,
    tp_cli_connection_manager_signal_callback_new_connection callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_connection_manager_callback_for_get_parameters) (TpConnectionManager *proxy,
    const GPtrArray *out_Parameters,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_connection_manager_call_get_parameters (TpConnectionManager *proxy,
    gint timeout_ms,
    const gchar *in_Protocol,
    tp_cli_connection_manager_callback_for_get_parameters callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_connection_manager_run_get_parameters (TpConnectionManager *proxy,
    gint timeout_ms,
    const gchar *in_Protocol,
    GPtrArray **out_Parameters,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_connection_manager_callback_for_list_protocols) (TpConnectionManager *proxy,
    const gchar **out_Protocols,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_connection_manager_call_list_protocols (TpConnectionManager *proxy,
    gint timeout_ms,
    tp_cli_connection_manager_callback_for_list_protocols callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_connection_manager_run_list_protocols (TpConnectionManager *proxy,
    gint timeout_ms,
    gchar ***out_Protocols,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_connection_manager_callback_for_request_connection) (TpConnectionManager *proxy,
    const gchar *out_Bus_Name,
    const gchar *out_Object_Path,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_connection_manager_call_request_connection (TpConnectionManager *proxy,
    gint timeout_ms,
    const gchar *in_Protocol,
    GHashTable *in_Parameters,
    tp_cli_connection_manager_callback_for_request_connection callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_connection_manager_run_request_connection (TpConnectionManager *proxy,
    gint timeout_ms,
    const gchar *in_Protocol,
    GHashTable *in_Parameters,
    gchar **out_Bus_Name,
    gchar **out_Object_Path,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_CONNECTION_MANAGER_H_INCLUDED) */
