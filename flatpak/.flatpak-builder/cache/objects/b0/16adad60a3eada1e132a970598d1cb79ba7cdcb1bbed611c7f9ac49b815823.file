#include "_gen/tp-svc-media-stream-handler.h"

static const DBusGObjectInfo _tp_svc_media_stream_handler_object_info;

struct _TpSvcMediaStreamHandlerClass {
    GTypeInterface parent_class;
    tp_svc_media_stream_handler_codec_choice_impl codec_choice_cb;
    tp_svc_media_stream_handler_error_impl error_cb;
    tp_svc_media_stream_handler_native_candidates_prepared_impl native_candidates_prepared_cb;
    tp_svc_media_stream_handler_new_active_candidate_pair_impl new_active_candidate_pair_cb;
    tp_svc_media_stream_handler_new_active_transport_pair_impl new_active_transport_pair_cb;
    tp_svc_media_stream_handler_new_native_candidate_impl new_native_candidate_cb;
    tp_svc_media_stream_handler_ready_impl ready_cb;
    tp_svc_media_stream_handler_set_local_codecs_impl set_local_codecs_cb;
    tp_svc_media_stream_handler_stream_state_impl stream_state_cb;
    tp_svc_media_stream_handler_supported_codecs_impl supported_codecs_cb;
    tp_svc_media_stream_handler_codecs_updated_impl codecs_updated_cb;
    tp_svc_media_stream_handler_hold_state_impl hold_state_cb;
    tp_svc_media_stream_handler_unhold_failure_impl unhold_failure_cb;
    tp_svc_media_stream_handler_supported_feedback_messages_impl supported_feedback_messages_cb;
    tp_svc_media_stream_handler_supported_header_extensions_impl supported_header_extensions_cb;
};

enum {
    SIGNAL_MEDIA_STREAM_HANDLER_AddRemoteCandidate,
    SIGNAL_MEDIA_STREAM_HANDLER_Close,
    SIGNAL_MEDIA_STREAM_HANDLER_RemoveRemoteCandidate,
    SIGNAL_MEDIA_STREAM_HANDLER_SetActiveCandidatePair,
    SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteCandidateList,
    SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteCodecs,
    SIGNAL_MEDIA_STREAM_HANDLER_SetStreamPlaying,
    SIGNAL_MEDIA_STREAM_HANDLER_SetStreamSending,
    SIGNAL_MEDIA_STREAM_HANDLER_StartTelephonyEvent,
    SIGNAL_MEDIA_STREAM_HANDLER_StartNamedTelephonyEvent,
    SIGNAL_MEDIA_STREAM_HANDLER_StartSoundTelephonyEvent,
    SIGNAL_MEDIA_STREAM_HANDLER_StopTelephonyEvent,
    SIGNAL_MEDIA_STREAM_HANDLER_SetStreamHeld,
    SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteFeedbackMessages,
    SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteHeaderExtensions,
    N_MEDIA_STREAM_HANDLER_SIGNALS
};
static guint media_stream_handler_signals[N_MEDIA_STREAM_HANDLER_SIGNALS] = {0};

static void tp_svc_media_stream_handler_base_init (gpointer klass);

GType
tp_svc_media_stream_handler_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcMediaStreamHandlerClass),
        tp_svc_media_stream_handler_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcMediaStreamHandler", &info, 0);
    }

  return type;
}

static void
tp_svc_media_stream_handler_codec_choice (TpSvcMediaStreamHandler *self,
    guint in_Codec_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_codec_choice_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->codec_choice_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Codec_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_codec_choice (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_codec_choice_impl impl)
{
  klass->codec_choice_cb = impl;
}

static void
tp_svc_media_stream_handler_error (TpSvcMediaStreamHandler *self,
    guint in_Error_Code,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_error_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->error_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Error_Code,
        in_Message,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_error (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_error_impl impl)
{
  klass->error_cb = impl;
}

static void
tp_svc_media_stream_handler_native_candidates_prepared (TpSvcMediaStreamHandler *self,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_native_candidates_prepared_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->native_candidates_prepared_cb);

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
tp_svc_media_stream_handler_implement_native_candidates_prepared (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_native_candidates_prepared_impl impl)
{
  klass->native_candidates_prepared_cb = impl;
}

static void
tp_svc_media_stream_handler_new_active_candidate_pair (TpSvcMediaStreamHandler *self,
    const gchar *in_Native_Candidate_ID,
    const gchar *in_Remote_Candidate_ID,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_new_active_candidate_pair_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->new_active_candidate_pair_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Native_Candidate_ID,
        in_Remote_Candidate_ID,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_new_active_candidate_pair (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_new_active_candidate_pair_impl impl)
{
  klass->new_active_candidate_pair_cb = impl;
}

static void
tp_svc_media_stream_handler_new_active_transport_pair (TpSvcMediaStreamHandler *self,
    const gchar *in_Native_Candidate_ID,
    const GValueArray *in_Native_Transport,
    const gchar *in_Remote_Candidate_ID,
    const GValueArray *in_Remote_Transport,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_new_active_transport_pair_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->new_active_transport_pair_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Native_Candidate_ID,
        in_Native_Transport,
        in_Remote_Candidate_ID,
        in_Remote_Transport,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_new_active_transport_pair (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_new_active_transport_pair_impl impl)
{
  klass->new_active_transport_pair_cb = impl;
}

static void
tp_svc_media_stream_handler_new_native_candidate (TpSvcMediaStreamHandler *self,
    const gchar *in_Candidate_ID,
    const GPtrArray *in_Transports,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_new_native_candidate_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->new_native_candidate_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Candidate_ID,
        in_Transports,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_new_native_candidate (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_new_native_candidate_impl impl)
{
  klass->new_native_candidate_cb = impl;
}

static void
tp_svc_media_stream_handler_ready (TpSvcMediaStreamHandler *self,
    const GPtrArray *in_Codecs,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_ready_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->ready_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Codecs,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_ready (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_ready_impl impl)
{
  klass->ready_cb = impl;
}

static void
tp_svc_media_stream_handler_set_local_codecs (TpSvcMediaStreamHandler *self,
    const GPtrArray *in_Codecs,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_set_local_codecs_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->set_local_codecs_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Codecs,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_set_local_codecs (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_set_local_codecs_impl impl)
{
  klass->set_local_codecs_cb = impl;
}

static void
tp_svc_media_stream_handler_stream_state (TpSvcMediaStreamHandler *self,
    guint in_State,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_stream_state_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->stream_state_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_State,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_stream_state (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_stream_state_impl impl)
{
  klass->stream_state_cb = impl;
}

static void
tp_svc_media_stream_handler_supported_codecs (TpSvcMediaStreamHandler *self,
    const GPtrArray *in_Codecs,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_supported_codecs_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->supported_codecs_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Codecs,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_supported_codecs (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_supported_codecs_impl impl)
{
  klass->supported_codecs_cb = impl;
}

static void
tp_svc_media_stream_handler_codecs_updated (TpSvcMediaStreamHandler *self,
    const GPtrArray *in_Codecs,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_codecs_updated_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->codecs_updated_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Codecs,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_codecs_updated (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_codecs_updated_impl impl)
{
  klass->codecs_updated_cb = impl;
}

static void
tp_svc_media_stream_handler_hold_state (TpSvcMediaStreamHandler *self,
    gboolean in_Held,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_hold_state_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->hold_state_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Held,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_hold_state (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_hold_state_impl impl)
{
  klass->hold_state_cb = impl;
}

static void
tp_svc_media_stream_handler_unhold_failure (TpSvcMediaStreamHandler *self,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_unhold_failure_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->unhold_failure_cb);

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
tp_svc_media_stream_handler_implement_unhold_failure (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_unhold_failure_impl impl)
{
  klass->unhold_failure_cb = impl;
}

static void
tp_svc_media_stream_handler_supported_feedback_messages (TpSvcMediaStreamHandler *self,
    GHashTable *in_Messages,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_supported_feedback_messages_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->supported_feedback_messages_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Messages,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_supported_feedback_messages (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_supported_feedback_messages_impl impl)
{
  klass->supported_feedback_messages_cb = impl;
}

static void
tp_svc_media_stream_handler_supported_header_extensions (TpSvcMediaStreamHandler *self,
    const GPtrArray *in_Header_Extensions,
    DBusGMethodInvocation *context)
{
  tp_svc_media_stream_handler_supported_header_extensions_impl impl = (TP_SVC_MEDIA_STREAM_HANDLER_GET_CLASS (self)->supported_header_extensions_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Header_Extensions,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_media_stream_handler_implement_supported_header_extensions (TpSvcMediaStreamHandlerClass *klass, tp_svc_media_stream_handler_supported_header_extensions_impl impl)
{
  klass->supported_header_extensions_cb = impl;
}

void
tp_svc_media_stream_handler_emit_add_remote_candidate (gpointer instance,
    const gchar *arg_Candidate_ID,
    const GPtrArray *arg_Transports)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_AddRemoteCandidate],
      0,
      arg_Candidate_ID,
      arg_Transports);
}

void
tp_svc_media_stream_handler_emit_close (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_Close],
      0);
}

void
tp_svc_media_stream_handler_emit_remove_remote_candidate (gpointer instance,
    const gchar *arg_Candidate_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_RemoveRemoteCandidate],
      0,
      arg_Candidate_ID);
}

void
tp_svc_media_stream_handler_emit_set_active_candidate_pair (gpointer instance,
    const gchar *arg_Native_Candidate_ID,
    const gchar *arg_Remote_Candidate_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetActiveCandidatePair],
      0,
      arg_Native_Candidate_ID,
      arg_Remote_Candidate_ID);
}

void
tp_svc_media_stream_handler_emit_set_remote_candidate_list (gpointer instance,
    const GPtrArray *arg_Remote_Candidates)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteCandidateList],
      0,
      arg_Remote_Candidates);
}

void
tp_svc_media_stream_handler_emit_set_remote_codecs (gpointer instance,
    const GPtrArray *arg_Codecs)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteCodecs],
      0,
      arg_Codecs);
}

void
tp_svc_media_stream_handler_emit_set_stream_playing (gpointer instance,
    gboolean arg_Playing)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetStreamPlaying],
      0,
      arg_Playing);
}

void
tp_svc_media_stream_handler_emit_set_stream_sending (gpointer instance,
    gboolean arg_Sending)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetStreamSending],
      0,
      arg_Sending);
}

void
tp_svc_media_stream_handler_emit_start_telephony_event (gpointer instance,
    guchar arg_Event)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_StartTelephonyEvent],
      0,
      arg_Event);
}

void
tp_svc_media_stream_handler_emit_start_named_telephony_event (gpointer instance,
    guchar arg_Event,
    guint arg_Codec_ID)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_StartNamedTelephonyEvent],
      0,
      arg_Event,
      arg_Codec_ID);
}

void
tp_svc_media_stream_handler_emit_start_sound_telephony_event (gpointer instance,
    guchar arg_Event)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_StartSoundTelephonyEvent],
      0,
      arg_Event);
}

void
tp_svc_media_stream_handler_emit_stop_telephony_event (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_StopTelephonyEvent],
      0);
}

void
tp_svc_media_stream_handler_emit_set_stream_held (gpointer instance,
    gboolean arg_Held)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetStreamHeld],
      0,
      arg_Held);
}

void
tp_svc_media_stream_handler_emit_set_remote_feedback_messages (gpointer instance,
    GHashTable *arg_Messages)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteFeedbackMessages],
      0,
      arg_Messages);
}

void
tp_svc_media_stream_handler_emit_set_remote_header_extensions (gpointer instance,
    const GPtrArray *arg_Header_Extensions)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_STREAM_HANDLER));
  g_signal_emit (instance,
      media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteHeaderExtensions],
      0,
      arg_Header_Extensions);
}

static inline void
tp_svc_media_stream_handler_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[5] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a(sq)", 0, NULL, NULL }, /* STUNServers */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* CreatedLocally */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* NATTraversal */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "aa{sv}", 0, NULL, NULL }, /* RelayInfo */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_media_stream_handler_get_type (),
      &_tp_svc_media_stream_handler_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Media.StreamHandler");
  properties[0].name = g_quark_from_static_string ("STUNServers");
  properties[0].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_UINT, G_TYPE_INVALID))));
  properties[1].name = g_quark_from_static_string ("CreatedLocally");
  properties[1].type = G_TYPE_BOOLEAN;
  properties[2].name = g_quark_from_static_string ("NATTraversal");
  properties[2].type = G_TYPE_STRING;
  properties[3].name = g_quark_from_static_string ("RelayInfo");
  properties[3].type = (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_MEDIA_STREAM_HANDLER, &interface);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_AddRemoteCandidate] =
  g_signal_new ("add-remote-candidate",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_STRING,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))));

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_Close] =
  g_signal_new ("close",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_RemoveRemoteCandidate] =
  g_signal_new ("remove-remote-candidate",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRING);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetActiveCandidatePair] =
  g_signal_new ("set-active-candidate-pair",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_STRING,
      G_TYPE_STRING);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteCandidateList] =
  g_signal_new ("set-remote-candidate-list",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_DOUBLE, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))));

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteCodecs] =
  g_signal_new ("set-remote-codecs",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, DBUS_TYPE_G_STRING_STRING_HASHTABLE, G_TYPE_INVALID)))));

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetStreamPlaying] =
  g_signal_new ("set-stream-playing",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetStreamSending] =
  g_signal_new ("set-stream-sending",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_StartTelephonyEvent] =
  g_signal_new ("start-telephony-event",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UCHAR);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_StartNamedTelephonyEvent] =
  g_signal_new ("start-named-telephony-event",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UCHAR,
      G_TYPE_UINT);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_StartSoundTelephonyEvent] =
  g_signal_new ("start-sound-telephony-event",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UCHAR);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_StopTelephonyEvent] =
  g_signal_new ("stop-telephony-event",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetStreamHeld] =
  g_signal_new ("set-stream-held",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteFeedbackMessages] =
  g_signal_new ("set-remote-feedback-messages",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))), G_TYPE_INVALID)))));

  media_stream_handler_signals[SIGNAL_MEDIA_STREAM_HANDLER_SetRemoteHeaderExtensions] =
  g_signal_new ("set-remote-header-extensions",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)))));

}
static void
tp_svc_media_stream_handler_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_media_stream_handler_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_media_stream_handler_methods[] = {
  { (GCallback) tp_svc_media_stream_handler_codec_choice, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_media_stream_handler_error, g_cclosure_marshal_generic, 74 },
  { (GCallback) tp_svc_media_stream_handler_native_candidates_prepared, g_cclosure_marshal_generic, 156 },
  { (GCallback) tp_svc_media_stream_handler_new_active_candidate_pair, g_cclosure_marshal_generic, 230 },
  { (GCallback) tp_svc_media_stream_handler_new_active_transport_pair, g_cclosure_marshal_generic, 350 },
  { (GCallback) tp_svc_media_stream_handler_new_native_candidate, g_cclosure_marshal_generic, 534 },
  { (GCallback) tp_svc_media_stream_handler_ready, g_cclosure_marshal_generic, 646 },
  { (GCallback) tp_svc_media_stream_handler_set_local_codecs, g_cclosure_marshal_generic, 724 },
  { (GCallback) tp_svc_media_stream_handler_stream_state, g_cclosure_marshal_generic, 811 },
  { (GCallback) tp_svc_media_stream_handler_supported_codecs, g_cclosure_marshal_generic, 882 },
  { (GCallback) tp_svc_media_stream_handler_codecs_updated, g_cclosure_marshal_generic, 970 },
  { (GCallback) tp_svc_media_stream_handler_hold_state, g_cclosure_marshal_generic, 1056 },
  { (GCallback) tp_svc_media_stream_handler_unhold_failure, g_cclosure_marshal_generic, 1124 },
  { (GCallback) tp_svc_media_stream_handler_supported_feedback_messages, g_cclosure_marshal_generic, 1187 },
  { (GCallback) tp_svc_media_stream_handler_supported_header_extensions, g_cclosure_marshal_generic, 1287 },
};

static const DBusGObjectInfo _tp_svc_media_stream_handler_object_info = {
  0,
  _tp_svc_media_stream_handler_methods,
  15,
"org.freedesktop.Telepathy.Media.StreamHandler\0CodecChoice\0A\0Codec_ID\0I\0u\0\0org.freedesktop.Telepathy.Media.StreamHandler\0Error\0A\0Error_Code\0I\0u\0Message\0I\0s\0\0org.freedesktop.Telepathy.Media.StreamHandler\0NativeCandidatesPrepared\0A\0\0org.freedesktop.Telepathy.Media.StreamHandler\0NewActiveCandidatePair\0A\0Native_Candidate_ID\0I\0s\0Remote_Candidate_ID\0I\0s\0\0org.freedesktop.Telepathy.Media.StreamHandler\0NewActiveTransportPair\0A\0Native_Candidate_ID\0I\0s\0Native_Transport\0I\0(usuussduss)\0Remote_Candidate_ID\0I\0s\0Remote_Transport\0I\0(usuussduss)\0\0org.freedesktop.Telepathy.Media.StreamHandler\0NewNativeCandidate\0A\0Candidate_ID\0I\0s\0Transports\0I\0a(usuussduss)\0\0org.freedesktop.Telepathy.Media.StreamHandler\0Ready\0A\0Codecs\0I\0a(usuuua{ss})\0\0org.freedesktop.Telepathy.Media.StreamHandler\0SetLocalCodecs\0A\0Codecs\0I\0a(usuuua{ss})\0\0org.freedesktop.Telepathy.Media.StreamHandler\0StreamState\0A\0State\0I\0u\0\0org.freedesktop.Telepathy.Media.StreamHandler\0SupportedCodecs\0A\0Codecs\0I\0a(usuuua{ss})\0\0org.freedesktop.Telepathy.Media.StreamHandler\0CodecsUpdated\0A\0Codecs\0I\0a(usuuua{ss})\0\0org.freedesktop.Telepathy.Media.StreamHandler\0HoldState\0A\0Held\0I\0b\0\0org.freedesktop.Telepathy.Media.StreamHandler\0UnholdFailure\0A\0\0org.freedesktop.Telepathy.Media.StreamHandler\0SupportedFeedbackMessages\0A\0Messages\0I\0a{u(ua(sss))}\0\0org.freedesktop.Telepathy.Media.StreamHandler\0SupportedHeaderExtensions\0A\0Header_Extensions\0I\0a(uuss)\0\0\0",
"org.freedesktop.Telepathy.Media.StreamHandler\0AddRemoteCandidate\0org.freedesktop.Telepathy.Media.StreamHandler\0Close\0org.freedesktop.Telepathy.Media.StreamHandler\0RemoveRemoteCandidate\0org.freedesktop.Telepathy.Media.StreamHandler\0SetActiveCandidatePair\0org.freedesktop.Telepathy.Media.StreamHandler\0SetRemoteCandidateList\0org.freedesktop.Telepathy.Media.StreamHandler\0SetRemoteCodecs\0org.freedesktop.Telepathy.Media.StreamHandler\0SetStreamPlaying\0org.freedesktop.Telepathy.Media.StreamHandler\0SetStreamSending\0org.freedesktop.Telepathy.Media.StreamHandler\0StartTelephonyEvent\0org.freedesktop.Telepathy.Media.StreamHandler\0StartNamedTelephonyEvent\0org.freedesktop.Telepathy.Media.StreamHandler\0StartSoundTelephonyEvent\0org.freedesktop.Telepathy.Media.StreamHandler\0StopTelephonyEvent\0org.freedesktop.Telepathy.Media.StreamHandler\0SetStreamHeld\0org.freedesktop.Telepathy.Media.StreamHandler\0SetRemoteFeedbackMessages\0org.freedesktop.Telepathy.Media.StreamHandler\0SetRemoteHeaderExtensions\0\0",
"\0\0",
};


