#ifndef TP_GEN_TP_CLI_CALL_STREAM_H_INCLUDED
#define TP_GEN_TP_CLI_CALL_STREAM_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_call_stream_signal_callback_remote_members_changed) (TpCallStream *proxy,
    GHashTable *arg_Updates,
    GHashTable *arg_Identifiers,
    const GArray *arg_Removed,
    const GValueArray *arg_Reason,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_connect_to_remote_members_changed (TpCallStream *proxy,
    tp_cli_call_stream_signal_callback_remote_members_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_signal_callback_local_sending_state_changed) (TpCallStream *proxy,
    guint arg_State,
    const GValueArray *arg_Reason,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_connect_to_local_sending_state_changed (TpCallStream *proxy,
    tp_cli_call_stream_signal_callback_local_sending_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_callback_for_set_sending) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_call_set_sending (TpCallStream *proxy,
    gint timeout_ms,
    gboolean in_Send,
    tp_cli_call_stream_callback_for_set_sending callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_callback_for_request_receiving) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_call_request_receiving (TpCallStream *proxy,
    gint timeout_ms,
    guint in_Contact,
    gboolean in_Receive,
    tp_cli_call_stream_callback_for_request_receiving callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_interface_media_signal_callback_sending_state_changed) (TpCallStream *proxy,
    guint arg_State,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_sending_state_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_sending_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_signal_callback_receiving_state_changed) (TpCallStream *proxy,
    guint arg_State,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_receiving_state_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_receiving_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_signal_callback_local_candidates_added) (TpCallStream *proxy,
    const GPtrArray *arg_Candidates,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_local_candidates_added (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_local_candidates_added callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_signal_callback_local_credentials_changed) (TpCallStream *proxy,
    const gchar *arg_Username,
    const gchar *arg_Password,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_local_credentials_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_local_credentials_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_signal_callback_relay_info_changed) (TpCallStream *proxy,
    const GPtrArray *arg_Relay_Info,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_relay_info_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_relay_info_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_signal_callback_stun_servers_changed) (TpCallStream *proxy,
    const GPtrArray *arg_Servers,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_stun_servers_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_stun_servers_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_signal_callback_server_info_retrieved) (TpCallStream *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_server_info_retrieved (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_server_info_retrieved callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_signal_callback_endpoints_changed) (TpCallStream *proxy,
    const GPtrArray *arg_Endpoints_Added,
    const GPtrArray *arg_Endpoints_Removed,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_endpoints_changed (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_endpoints_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_signal_callback_ice_restart_requested) (TpCallStream *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_interface_media_connect_to_ice_restart_requested (TpCallStream *proxy,
    tp_cli_call_stream_interface_media_signal_callback_ice_restart_requested callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_interface_media_callback_for_complete_sending_state_change) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_interface_media_call_complete_sending_state_change (TpCallStream *proxy,
    gint timeout_ms,
    guint in_State,
    tp_cli_call_stream_interface_media_callback_for_complete_sending_state_change callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_interface_media_callback_for_report_sending_failure) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_interface_media_call_report_sending_failure (TpCallStream *proxy,
    gint timeout_ms,
    guint in_Reason,
    const gchar *in_Error,
    const gchar *in_Message,
    tp_cli_call_stream_interface_media_callback_for_report_sending_failure callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_interface_media_callback_for_complete_receiving_state_change) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_interface_media_call_complete_receiving_state_change (TpCallStream *proxy,
    gint timeout_ms,
    guint in_State,
    tp_cli_call_stream_interface_media_callback_for_complete_receiving_state_change callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_interface_media_callback_for_report_receiving_failure) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_interface_media_call_report_receiving_failure (TpCallStream *proxy,
    gint timeout_ms,
    guint in_Reason,
    const gchar *in_Error,
    const gchar *in_Message,
    tp_cli_call_stream_interface_media_callback_for_report_receiving_failure callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_interface_media_callback_for_set_credentials) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_interface_media_call_set_credentials (TpCallStream *proxy,
    gint timeout_ms,
    const gchar *in_Username,
    const gchar *in_Password,
    tp_cli_call_stream_interface_media_callback_for_set_credentials callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_interface_media_callback_for_add_candidates) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_interface_media_call_add_candidates (TpCallStream *proxy,
    gint timeout_ms,
    const GPtrArray *in_Candidates,
    tp_cli_call_stream_interface_media_callback_for_add_candidates callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_interface_media_callback_for_finish_initial_candidates) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_interface_media_call_finish_initial_candidates (TpCallStream *proxy,
    gint timeout_ms,
    tp_cli_call_stream_interface_media_callback_for_finish_initial_candidates callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_interface_media_callback_for_fail) (TpCallStream *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_interface_media_call_fail (TpCallStream *proxy,
    gint timeout_ms,
    const GValueArray *in_Reason,
    tp_cli_call_stream_interface_media_callback_for_fail callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_CALL_STREAM_H_INCLUDED) */
