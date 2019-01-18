#ifndef TP_GEN_TP_CLI_CALL_STREAM_ENDPOINT_H_INCLUDED
#define TP_GEN_TP_CLI_CALL_STREAM_ENDPOINT_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_call_stream_endpoint_signal_callback_remote_credentials_set) (TpProxy *proxy,
    const gchar *arg_Username,
    const gchar *arg_Password,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_endpoint_connect_to_remote_credentials_set (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_remote_credentials_set callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_endpoint_signal_callback_remote_candidates_added) (TpProxy *proxy,
    const GPtrArray *arg_Candidates,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_endpoint_connect_to_remote_candidates_added (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_remote_candidates_added callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_endpoint_signal_callback_candidate_pair_selected) (TpProxy *proxy,
    const GValueArray *arg_Local_Candidate,
    const GValueArray *arg_Remote_Candidate,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_endpoint_connect_to_candidate_pair_selected (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_candidate_pair_selected callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_endpoint_signal_callback_endpoint_state_changed) (TpProxy *proxy,
    guint arg_Component,
    guint arg_State,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_endpoint_connect_to_endpoint_state_changed (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_endpoint_state_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_endpoint_signal_callback_controlling_changed) (TpProxy *proxy,
    gboolean arg_Controlling,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_stream_endpoint_connect_to_controlling_changed (gpointer proxy,
    tp_cli_call_stream_endpoint_signal_callback_controlling_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_stream_endpoint_callback_for_set_selected_candidate_pair) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_endpoint_call_set_selected_candidate_pair (gpointer proxy,
    gint timeout_ms,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    tp_cli_call_stream_endpoint_callback_for_set_selected_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_endpoint_callback_for_set_endpoint_state) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_endpoint_call_set_endpoint_state (gpointer proxy,
    gint timeout_ms,
    guint in_Component,
    guint in_State,
    tp_cli_call_stream_endpoint_callback_for_set_endpoint_state callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_endpoint_callback_for_accept_selected_candidate_pair) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_endpoint_call_accept_selected_candidate_pair (gpointer proxy,
    gint timeout_ms,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    tp_cli_call_stream_endpoint_callback_for_accept_selected_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_endpoint_callback_for_reject_selected_candidate_pair) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_endpoint_call_reject_selected_candidate_pair (gpointer proxy,
    gint timeout_ms,
    const GValueArray *in_Local_Candidate,
    const GValueArray *in_Remote_Candidate,
    tp_cli_call_stream_endpoint_callback_for_reject_selected_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_stream_endpoint_callback_for_set_controlling) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_stream_endpoint_call_set_controlling (gpointer proxy,
    gint timeout_ms,
    gboolean in_Controlling,
    tp_cli_call_stream_endpoint_callback_for_set_controlling callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_CALL_STREAM_ENDPOINT_H_INCLUDED) */
