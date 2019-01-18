#ifndef TP_GEN_TP_CLI_MEDIA_STREAM_HANDLER_H_INCLUDED
#define TP_GEN_TP_CLI_MEDIA_STREAM_HANDLER_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_media_stream_handler_signal_callback_add_remote_candidate) (TpMediaStreamHandler *proxy,
    const gchar *arg_Candidate_ID,
    const GPtrArray *arg_Transports,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_add_remote_candidate (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_add_remote_candidate callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_close) (TpMediaStreamHandler *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_close (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_close callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_remove_remote_candidate) (TpMediaStreamHandler *proxy,
    const gchar *arg_Candidate_ID,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_remove_remote_candidate (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_remove_remote_candidate callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_set_active_candidate_pair) (TpMediaStreamHandler *proxy,
    const gchar *arg_Native_Candidate_ID,
    const gchar *arg_Remote_Candidate_ID,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_set_active_candidate_pair (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_active_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_set_remote_candidate_list) (TpMediaStreamHandler *proxy,
    const GPtrArray *arg_Remote_Candidates,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_set_remote_candidate_list (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_remote_candidate_list callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_set_remote_codecs) (TpMediaStreamHandler *proxy,
    const GPtrArray *arg_Codecs,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_set_remote_codecs (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_remote_codecs callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_set_stream_playing) (TpMediaStreamHandler *proxy,
    gboolean arg_Playing,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_set_stream_playing (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_stream_playing callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_set_stream_sending) (TpMediaStreamHandler *proxy,
    gboolean arg_Sending,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_set_stream_sending (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_stream_sending callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_start_telephony_event) (TpMediaStreamHandler *proxy,
    guchar arg_Event,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_start_telephony_event (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_start_telephony_event callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_start_named_telephony_event) (TpMediaStreamHandler *proxy,
    guchar arg_Event,
    guint arg_Codec_ID,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_start_named_telephony_event (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_start_named_telephony_event callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_start_sound_telephony_event) (TpMediaStreamHandler *proxy,
    guchar arg_Event,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_start_sound_telephony_event (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_start_sound_telephony_event callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_stop_telephony_event) (TpMediaStreamHandler *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_stop_telephony_event (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_stop_telephony_event callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_set_stream_held) (TpMediaStreamHandler *proxy,
    gboolean arg_Held,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_set_stream_held (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_stream_held callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_set_remote_feedback_messages) (TpMediaStreamHandler *proxy,
    GHashTable *arg_Messages,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_set_remote_feedback_messages (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_remote_feedback_messages callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_signal_callback_set_remote_header_extensions) (TpMediaStreamHandler *proxy,
    const GPtrArray *arg_Header_Extensions,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_media_stream_handler_connect_to_set_remote_header_extensions (TpMediaStreamHandler *proxy,
    tp_cli_media_stream_handler_signal_callback_set_remote_header_extensions callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_media_stream_handler_callback_for_codec_choice) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_codec_choice (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_Codec_ID,
    tp_cli_media_stream_handler_callback_for_codec_choice callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_codec_choice (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_Codec_ID,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_error) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_error (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_Error_Code,
    const gchar *in_Message,
    tp_cli_media_stream_handler_callback_for_error callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_error (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_Error_Code,
    const gchar *in_Message,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_native_candidates_prepared) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_native_candidates_prepared (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    tp_cli_media_stream_handler_callback_for_native_candidates_prepared callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_native_candidates_prepared (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_new_active_candidate_pair) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_new_active_candidate_pair (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Native_Candidate_ID,
    const gchar *in_Remote_Candidate_ID,
    tp_cli_media_stream_handler_callback_for_new_active_candidate_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_new_active_candidate_pair (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Native_Candidate_ID,
    const gchar *in_Remote_Candidate_ID,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_new_active_transport_pair) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_new_active_transport_pair (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Native_Candidate_ID,
    const GValueArray *in_Native_Transport,
    const gchar *in_Remote_Candidate_ID,
    const GValueArray *in_Remote_Transport,
    tp_cli_media_stream_handler_callback_for_new_active_transport_pair callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_new_active_transport_pair (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Native_Candidate_ID,
    const GValueArray *in_Native_Transport,
    const gchar *in_Remote_Candidate_ID,
    const GValueArray *in_Remote_Transport,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_new_native_candidate) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_new_native_candidate (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Candidate_ID,
    const GPtrArray *in_Transports,
    tp_cli_media_stream_handler_callback_for_new_native_candidate callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_new_native_candidate (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const gchar *in_Candidate_ID,
    const GPtrArray *in_Transports,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_ready) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_ready (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    tp_cli_media_stream_handler_callback_for_ready callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_ready (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_set_local_codecs) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_set_local_codecs (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    tp_cli_media_stream_handler_callback_for_set_local_codecs callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_set_local_codecs (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_stream_state) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_stream_state (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_State,
    tp_cli_media_stream_handler_callback_for_stream_state callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_stream_state (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    guint in_State,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_supported_codecs) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_supported_codecs (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    tp_cli_media_stream_handler_callback_for_supported_codecs callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_supported_codecs (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_codecs_updated) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_codecs_updated (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    tp_cli_media_stream_handler_callback_for_codecs_updated callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_codecs_updated (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Codecs,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_hold_state) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_hold_state (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    gboolean in_Held,
    tp_cli_media_stream_handler_callback_for_hold_state callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_hold_state (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    gboolean in_Held,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_unhold_failure) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_unhold_failure (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    tp_cli_media_stream_handler_callback_for_unhold_failure callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_unhold_failure (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_supported_feedback_messages) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_supported_feedback_messages (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    GHashTable *in_Messages,
    tp_cli_media_stream_handler_callback_for_supported_feedback_messages callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_supported_feedback_messages (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    GHashTable *in_Messages,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_media_stream_handler_callback_for_supported_header_extensions) (TpMediaStreamHandler *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_media_stream_handler_call_supported_header_extensions (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Header_Extensions,
    tp_cli_media_stream_handler_callback_for_supported_header_extensions callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_media_stream_handler_run_supported_header_extensions (TpMediaStreamHandler *proxy,
    gint timeout_ms,
    const GPtrArray *in_Header_Extensions,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_MEDIA_STREAM_HANDLER_H_INCLUDED) */
