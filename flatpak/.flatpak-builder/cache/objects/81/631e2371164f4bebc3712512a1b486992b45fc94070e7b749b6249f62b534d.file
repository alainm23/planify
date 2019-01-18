#ifndef TP_GEN_TP_CLI_CALL_CONTENT_H_INCLUDED
#define TP_GEN_TP_CLI_CALL_CONTENT_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_call_content_signal_callback_streams_added) (TpCallContent *proxy,
    const GPtrArray *arg_Streams,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_connect_to_streams_added (TpCallContent *proxy,
    tp_cli_call_content_signal_callback_streams_added callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_signal_callback_streams_removed) (TpCallContent *proxy,
    const GPtrArray *arg_Streams,
    const GValueArray *arg_Reason,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_connect_to_streams_removed (TpCallContent *proxy,
    tp_cli_call_content_signal_callback_streams_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_callback_for_remove) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_call_remove (TpCallContent *proxy,
    gint timeout_ms,
    tp_cli_call_content_callback_for_remove callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_audio_control_callback_for_report_input_volume) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_interface_audio_control_call_report_input_volume (TpCallContent *proxy,
    gint timeout_ms,
    gint in_Volume,
    tp_cli_call_content_interface_audio_control_callback_for_report_input_volume callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_audio_control_callback_for_report_output_volume) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_interface_audio_control_call_report_output_volume (TpCallContent *proxy,
    gint timeout_ms,
    gint in_Volume,
    tp_cli_call_content_interface_audio_control_callback_for_report_output_volume callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_dtmf_signal_callback_tones_deferred) (TpCallContent *proxy,
    const gchar *arg_Tones,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_dtmf_connect_to_tones_deferred (TpCallContent *proxy,
    tp_cli_call_content_interface_dtmf_signal_callback_tones_deferred callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_dtmf_signal_callback_sending_tones) (TpCallContent *proxy,
    const gchar *arg_Tones,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_dtmf_connect_to_sending_tones (TpCallContent *proxy,
    tp_cli_call_content_interface_dtmf_signal_callback_sending_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_dtmf_signal_callback_stopped_tones) (TpCallContent *proxy,
    gboolean arg_Cancelled,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_dtmf_connect_to_stopped_tones (TpCallContent *proxy,
    tp_cli_call_content_interface_dtmf_signal_callback_stopped_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_dtmf_callback_for_start_tone) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_interface_dtmf_call_start_tone (TpCallContent *proxy,
    gint timeout_ms,
    guchar in_Event,
    tp_cli_call_content_interface_dtmf_callback_for_start_tone callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_dtmf_callback_for_stop_tone) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_interface_dtmf_call_stop_tone (TpCallContent *proxy,
    gint timeout_ms,
    tp_cli_call_content_interface_dtmf_callback_for_stop_tone callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_dtmf_callback_for_multiple_tones) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_interface_dtmf_call_multiple_tones (TpCallContent *proxy,
    gint timeout_ms,
    const gchar *in_Tones,
    tp_cli_call_content_interface_dtmf_callback_for_multiple_tones callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_media_signal_callback_new_media_description_offer) (TpCallContent *proxy,
    const gchar *arg_Media_Description,
    GHashTable *arg_Properties,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_media_connect_to_new_media_description_offer (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_new_media_description_offer callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_media_signal_callback_media_description_offer_done) (TpCallContent *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_media_connect_to_media_description_offer_done (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_media_description_offer_done callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_media_signal_callback_local_media_description_changed) (TpCallContent *proxy,
    GHashTable *arg_Updated_Media_Description,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_media_connect_to_local_media_description_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_local_media_description_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_media_signal_callback_remote_media_descriptions_changed) (TpCallContent *proxy,
    GHashTable *arg_Updated_Media_Descriptions,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_media_connect_to_remote_media_descriptions_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_remote_media_descriptions_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_media_signal_callback_media_descriptions_removed) (TpCallContent *proxy,
    const GArray *arg_Removed_Media_Descriptions,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_media_connect_to_media_descriptions_removed (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_media_descriptions_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_media_signal_callback_dtmf_change_requested) (TpCallContent *proxy,
    guchar arg_Event,
    guint arg_State,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_media_connect_to_dtmf_change_requested (TpCallContent *proxy,
    tp_cli_call_content_interface_media_signal_callback_dtmf_change_requested callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_media_callback_for_update_local_media_description) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_interface_media_call_update_local_media_description (TpCallContent *proxy,
    gint timeout_ms,
    GHashTable *in_MediaDescription,
    tp_cli_call_content_interface_media_callback_for_update_local_media_description callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_media_callback_for_acknowledge_dtmf_change) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_interface_media_call_acknowledge_dtmf_change (TpCallContent *proxy,
    gint timeout_ms,
    guchar in_Event,
    guint in_State,
    tp_cli_call_content_interface_media_callback_for_acknowledge_dtmf_change callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_media_callback_for_fail) (TpCallContent *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_call_content_interface_media_call_fail (TpCallContent *proxy,
    gint timeout_ms,
    const GValueArray *in_Reason,
    tp_cli_call_content_interface_media_callback_for_fail callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_call_content_interface_video_control_signal_callback_key_frame_requested) (TpCallContent *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_video_control_connect_to_key_frame_requested (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_key_frame_requested callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_video_control_signal_callback_video_resolution_changed) (TpCallContent *proxy,
    const GValueArray *arg_NewResolution,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_video_control_connect_to_video_resolution_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_video_resolution_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_video_control_signal_callback_bitrate_changed) (TpCallContent *proxy,
    guint arg_NewBitrate,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_video_control_connect_to_bitrate_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_bitrate_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_video_control_signal_callback_framerate_changed) (TpCallContent *proxy,
    guint arg_NewFramerate,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_video_control_connect_to_framerate_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_framerate_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_call_content_interface_video_control_signal_callback_mtu_changed) (TpCallContent *proxy,
    guint arg_NewMTU,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_call_content_interface_video_control_connect_to_mtu_changed (TpCallContent *proxy,
    tp_cli_call_content_interface_video_control_signal_callback_mtu_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_CALL_CONTENT_H_INCLUDED) */
