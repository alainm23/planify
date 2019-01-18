#include "_gen/tp-svc-call-content.h"

static const DBusGObjectInfo _tp_svc_call_content_object_info;

struct _TpSvcCallContentClass {
    GTypeInterface parent_class;
    tp_svc_call_content_remove_impl remove_cb;
};

enum {
    SIGNAL_CALL_CONTENT_StreamsAdded,
    SIGNAL_CALL_CONTENT_StreamsRemoved,
    N_CALL_CONTENT_SIGNALS
};
static guint call_content_signals[N_CALL_CONTENT_SIGNALS] = {0};

static void tp_svc_call_content_base_init (gpointer klass);

GType
tp_svc_call_content_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentClass),
        tp_svc_call_content_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContent", &info, 0);
    }

  return type;
}

static void
tp_svc_call_content_remove (TpSvcCallContent *self,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_remove_impl impl = (TP_SVC_CALL_CONTENT_GET_CLASS (self)->remove_cb);

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
tp_svc_call_content_implement_remove (TpSvcCallContentClass *klass, tp_svc_call_content_remove_impl impl)
{
  klass->remove_cb = impl;
}

void
tp_svc_call_content_emit_streams_added (gpointer instance,
    const GPtrArray *arg_Streams)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT));
  g_signal_emit (instance,
      call_content_signals[SIGNAL_CALL_CONTENT_StreamsAdded],
      0,
      arg_Streams);
}

void
tp_svc_call_content_emit_streams_removed (gpointer instance,
    const GPtrArray *arg_Streams,
    const GValueArray *arg_Reason)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT));
  g_signal_emit (instance,
      call_content_signals[SIGNAL_CALL_CONTENT_StreamsRemoved],
      0,
      arg_Streams,
      arg_Reason);
}

static inline void
tp_svc_call_content_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "as", 0, NULL, NULL }, /* Interfaces */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* Name */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Type */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Disposition */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "ao", 0, NULL, NULL }, /* Streams */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_get_type (),
      &_tp_svc_call_content_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content");
  properties[0].name = g_quark_from_static_string ("Interfaces");
  properties[0].type = G_TYPE_STRV;
  properties[1].name = g_quark_from_static_string ("Name");
  properties[1].type = G_TYPE_STRING;
  properties[2].name = g_quark_from_static_string ("Type");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("Disposition");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("Streams");
  properties[4].type = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT, &interface);

  call_content_signals[SIGNAL_CALL_CONTENT_StreamsAdded] =
  g_signal_new ("streams-added",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH));

  call_content_signals[SIGNAL_CALL_CONTENT_StreamsRemoved] =
  g_signal_new ("streams-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH),
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_INVALID)));

}
static void
tp_svc_call_content_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_methods[] = {
  { (GCallback) tp_svc_call_content_remove, g_cclosure_marshal_generic, 0 },
};

static const DBusGObjectInfo _tp_svc_call_content_object_info = {
  0,
  _tp_svc_call_content_methods,
  1,
"org.freedesktop.Telepathy.Call1.Content\0Remove\0A\0\0\0",
"org.freedesktop.Telepathy.Call1.Content\0StreamsAdded\0org.freedesktop.Telepathy.Call1.Content\0StreamsRemoved\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_call_content_interface_audio_control_object_info;

struct _TpSvcCallContentInterfaceAudioControlClass {
    GTypeInterface parent_class;
    tp_svc_call_content_interface_audio_control_report_input_volume_impl report_input_volume_cb;
    tp_svc_call_content_interface_audio_control_report_output_volume_impl report_output_volume_cb;
};

static void tp_svc_call_content_interface_audio_control_base_init (gpointer klass);

GType
tp_svc_call_content_interface_audio_control_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentInterfaceAudioControlClass),
        tp_svc_call_content_interface_audio_control_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContentInterfaceAudioControl", &info, 0);
    }

  return type;
}

static void
tp_svc_call_content_interface_audio_control_report_input_volume (TpSvcCallContentInterfaceAudioControl *self,
    gint in_Volume,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_interface_audio_control_report_input_volume_impl impl = (TP_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL_GET_CLASS (self)->report_input_volume_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Volume,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_interface_audio_control_implement_report_input_volume (TpSvcCallContentInterfaceAudioControlClass *klass, tp_svc_call_content_interface_audio_control_report_input_volume_impl impl)
{
  klass->report_input_volume_cb = impl;
}

static void
tp_svc_call_content_interface_audio_control_report_output_volume (TpSvcCallContentInterfaceAudioControl *self,
    gint in_Volume,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_interface_audio_control_report_output_volume_impl impl = (TP_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL_GET_CLASS (self)->report_output_volume_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Volume,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_interface_audio_control_implement_report_output_volume (TpSvcCallContentInterfaceAudioControlClass *klass, tp_svc_call_content_interface_audio_control_report_output_volume_impl impl)
{
  klass->report_output_volume_cb = impl;
}

static inline void
tp_svc_call_content_interface_audio_control_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "i", 0, NULL, NULL }, /* RequestedInputVolume */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ | TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED, "i", 0, NULL, NULL }, /* RequestedOutputVolume */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_interface_audio_control_get_type (),
      &_tp_svc_call_content_interface_audio_control_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content.Interface.AudioControl");
  properties[0].name = g_quark_from_static_string ("RequestedInputVolume");
  properties[0].type = G_TYPE_INT;
  properties[1].name = g_quark_from_static_string ("RequestedOutputVolume");
  properties[1].type = G_TYPE_INT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL, &interface);

}
static void
tp_svc_call_content_interface_audio_control_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_interface_audio_control_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_interface_audio_control_methods[] = {
  { (GCallback) tp_svc_call_content_interface_audio_control_report_input_volume, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_call_content_interface_audio_control_report_output_volume, g_cclosure_marshal_generic, 95 },
};

static const DBusGObjectInfo _tp_svc_call_content_interface_audio_control_object_info = {
  0,
  _tp_svc_call_content_interface_audio_control_methods,
  2,
"org.freedesktop.Telepathy.Call1.Content.Interface.AudioControl\0ReportInputVolume\0A\0Volume\0I\0i\0\0org.freedesktop.Telepathy.Call1.Content.Interface.AudioControl\0ReportOutputVolume\0A\0Volume\0I\0i\0\0\0",
"\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_call_content_interface_dtmf_object_info;

struct _TpSvcCallContentInterfaceDTMFClass {
    GTypeInterface parent_class;
    tp_svc_call_content_interface_dtmf_start_tone_impl start_tone_cb;
    tp_svc_call_content_interface_dtmf_stop_tone_impl stop_tone_cb;
    tp_svc_call_content_interface_dtmf_multiple_tones_impl multiple_tones_cb;
};

enum {
    SIGNAL_CALL_CONTENT_INTERFACE_DTMF_TonesDeferred,
    SIGNAL_CALL_CONTENT_INTERFACE_DTMF_SendingTones,
    SIGNAL_CALL_CONTENT_INTERFACE_DTMF_StoppedTones,
    N_CALL_CONTENT_INTERFACE_DTMF_SIGNALS
};
static guint call_content_interface_dtmf_signals[N_CALL_CONTENT_INTERFACE_DTMF_SIGNALS] = {0};

static void tp_svc_call_content_interface_dtmf_base_init (gpointer klass);

GType
tp_svc_call_content_interface_dtmf_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentInterfaceDTMFClass),
        tp_svc_call_content_interface_dtmf_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContentInterfaceDTMF", &info, 0);
    }

  return type;
}

static void
tp_svc_call_content_interface_dtmf_start_tone (TpSvcCallContentInterfaceDTMF *self,
    guchar in_Event,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_interface_dtmf_start_tone_impl impl = (TP_SVC_CALL_CONTENT_INTERFACE_DTMF_GET_CLASS (self)->start_tone_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Event,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_interface_dtmf_implement_start_tone (TpSvcCallContentInterfaceDTMFClass *klass, tp_svc_call_content_interface_dtmf_start_tone_impl impl)
{
  klass->start_tone_cb = impl;
}

static void
tp_svc_call_content_interface_dtmf_stop_tone (TpSvcCallContentInterfaceDTMF *self,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_interface_dtmf_stop_tone_impl impl = (TP_SVC_CALL_CONTENT_INTERFACE_DTMF_GET_CLASS (self)->stop_tone_cb);

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
tp_svc_call_content_interface_dtmf_implement_stop_tone (TpSvcCallContentInterfaceDTMFClass *klass, tp_svc_call_content_interface_dtmf_stop_tone_impl impl)
{
  klass->stop_tone_cb = impl;
}

static void
tp_svc_call_content_interface_dtmf_multiple_tones (TpSvcCallContentInterfaceDTMF *self,
    const gchar *in_Tones,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_interface_dtmf_multiple_tones_impl impl = (TP_SVC_CALL_CONTENT_INTERFACE_DTMF_GET_CLASS (self)->multiple_tones_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Tones,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_interface_dtmf_implement_multiple_tones (TpSvcCallContentInterfaceDTMFClass *klass, tp_svc_call_content_interface_dtmf_multiple_tones_impl impl)
{
  klass->multiple_tones_cb = impl;
}

void
tp_svc_call_content_interface_dtmf_emit_tones_deferred (gpointer instance,
    const gchar *arg_Tones)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF));
  g_signal_emit (instance,
      call_content_interface_dtmf_signals[SIGNAL_CALL_CONTENT_INTERFACE_DTMF_TonesDeferred],
      0,
      arg_Tones);
}

void
tp_svc_call_content_interface_dtmf_emit_sending_tones (gpointer instance,
    const gchar *arg_Tones)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF));
  g_signal_emit (instance,
      call_content_interface_dtmf_signals[SIGNAL_CALL_CONTENT_INTERFACE_DTMF_SendingTones],
      0,
      arg_Tones);
}

void
tp_svc_call_content_interface_dtmf_emit_stopped_tones (gpointer instance,
    gboolean arg_Cancelled)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF));
  g_signal_emit (instance,
      call_content_interface_dtmf_signals[SIGNAL_CALL_CONTENT_INTERFACE_DTMF_StoppedTones],
      0,
      arg_Cancelled);
}

static inline void
tp_svc_call_content_interface_dtmf_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[3] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* CurrentlySendingTones */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "s", 0, NULL, NULL }, /* DeferredTones */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_interface_dtmf_get_type (),
      &_tp_svc_call_content_interface_dtmf_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content.Interface.DTMF");
  properties[0].name = g_quark_from_static_string ("CurrentlySendingTones");
  properties[0].type = G_TYPE_BOOLEAN;
  properties[1].name = g_quark_from_static_string ("DeferredTones");
  properties[1].type = G_TYPE_STRING;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF, &interface);

  call_content_interface_dtmf_signals[SIGNAL_CALL_CONTENT_INTERFACE_DTMF_TonesDeferred] =
  g_signal_new ("tones-deferred",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRING);

  call_content_interface_dtmf_signals[SIGNAL_CALL_CONTENT_INTERFACE_DTMF_SendingTones] =
  g_signal_new ("sending-tones",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_STRING);

  call_content_interface_dtmf_signals[SIGNAL_CALL_CONTENT_INTERFACE_DTMF_StoppedTones] =
  g_signal_new ("stopped-tones",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_BOOLEAN);

}
static void
tp_svc_call_content_interface_dtmf_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_interface_dtmf_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_interface_dtmf_methods[] = {
  { (GCallback) tp_svc_call_content_interface_dtmf_start_tone, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_call_content_interface_dtmf_stop_tone, g_cclosure_marshal_generic, 78 },
  { (GCallback) tp_svc_call_content_interface_dtmf_multiple_tones, g_cclosure_marshal_generic, 145 },
};

static const DBusGObjectInfo _tp_svc_call_content_interface_dtmf_object_info = {
  0,
  _tp_svc_call_content_interface_dtmf_methods,
  3,
"org.freedesktop.Telepathy.Call1.Content.Interface.DTMF\0StartTone\0A\0Event\0I\0y\0\0org.freedesktop.Telepathy.Call1.Content.Interface.DTMF\0StopTone\0A\0\0org.freedesktop.Telepathy.Call1.Content.Interface.DTMF\0MultipleTones\0A\0Tones\0I\0s\0\0\0",
"org.freedesktop.Telepathy.Call1.Content.Interface.DTMF\0TonesDeferred\0org.freedesktop.Telepathy.Call1.Content.Interface.DTMF\0SendingTones\0org.freedesktop.Telepathy.Call1.Content.Interface.DTMF\0StoppedTones\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_call_content_interface_media_object_info;

struct _TpSvcCallContentInterfaceMediaClass {
    GTypeInterface parent_class;
    tp_svc_call_content_interface_media_update_local_media_description_impl update_local_media_description_cb;
    tp_svc_call_content_interface_media_acknowledge_dtmf_change_impl acknowledge_dtmf_change_cb;
    tp_svc_call_content_interface_media_fail_impl fail_cb;
};

enum {
    SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_NewMediaDescriptionOffer,
    SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_MediaDescriptionOfferDone,
    SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_LocalMediaDescriptionChanged,
    SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_RemoteMediaDescriptionsChanged,
    SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_MediaDescriptionsRemoved,
    SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_DTMFChangeRequested,
    N_CALL_CONTENT_INTERFACE_MEDIA_SIGNALS
};
static guint call_content_interface_media_signals[N_CALL_CONTENT_INTERFACE_MEDIA_SIGNALS] = {0};

static void tp_svc_call_content_interface_media_base_init (gpointer klass);

GType
tp_svc_call_content_interface_media_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentInterfaceMediaClass),
        tp_svc_call_content_interface_media_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContentInterfaceMedia", &info, 0);
    }

  return type;
}

static void
tp_svc_call_content_interface_media_update_local_media_description (TpSvcCallContentInterfaceMedia *self,
    GHashTable *in_MediaDescription,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_interface_media_update_local_media_description_impl impl = (TP_SVC_CALL_CONTENT_INTERFACE_MEDIA_GET_CLASS (self)->update_local_media_description_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_MediaDescription,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_interface_media_implement_update_local_media_description (TpSvcCallContentInterfaceMediaClass *klass, tp_svc_call_content_interface_media_update_local_media_description_impl impl)
{
  klass->update_local_media_description_cb = impl;
}

static void
tp_svc_call_content_interface_media_acknowledge_dtmf_change (TpSvcCallContentInterfaceMedia *self,
    guchar in_Event,
    guint in_State,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_interface_media_acknowledge_dtmf_change_impl impl = (TP_SVC_CALL_CONTENT_INTERFACE_MEDIA_GET_CLASS (self)->acknowledge_dtmf_change_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Event,
        in_State,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_interface_media_implement_acknowledge_dtmf_change (TpSvcCallContentInterfaceMediaClass *klass, tp_svc_call_content_interface_media_acknowledge_dtmf_change_impl impl)
{
  klass->acknowledge_dtmf_change_cb = impl;
}

static void
tp_svc_call_content_interface_media_fail (TpSvcCallContentInterfaceMedia *self,
    const GValueArray *in_Reason,
    DBusGMethodInvocation *context)
{
  tp_svc_call_content_interface_media_fail_impl impl = (TP_SVC_CALL_CONTENT_INTERFACE_MEDIA_GET_CLASS (self)->fail_cb);

  if (impl != NULL)
    {
      (impl) (self,
        in_Reason,
        context);
    }
  else
    {
      tp_dbus_g_method_return_not_implemented (context);
    }
}

void
tp_svc_call_content_interface_media_implement_fail (TpSvcCallContentInterfaceMediaClass *klass, tp_svc_call_content_interface_media_fail_impl impl)
{
  klass->fail_cb = impl;
}

void
tp_svc_call_content_interface_media_emit_new_media_description_offer (gpointer instance,
    const gchar *arg_Media_Description,
    GHashTable *arg_Properties)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_NewMediaDescriptionOffer],
      0,
      arg_Media_Description,
      arg_Properties);
}

void
tp_svc_call_content_interface_media_emit_media_description_offer_done (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_MediaDescriptionOfferDone],
      0);
}

void
tp_svc_call_content_interface_media_emit_local_media_description_changed (gpointer instance,
    GHashTable *arg_Updated_Media_Description)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_LocalMediaDescriptionChanged],
      0,
      arg_Updated_Media_Description);
}

void
tp_svc_call_content_interface_media_emit_remote_media_descriptions_changed (gpointer instance,
    GHashTable *arg_Updated_Media_Descriptions)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_RemoteMediaDescriptionsChanged],
      0,
      arg_Updated_Media_Descriptions);
}

void
tp_svc_call_content_interface_media_emit_media_descriptions_removed (gpointer instance,
    const GArray *arg_Removed_Media_Descriptions)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_MediaDescriptionsRemoved],
      0,
      arg_Removed_Media_Descriptions);
}

void
tp_svc_call_content_interface_media_emit_dtmf_change_requested (gpointer instance,
    guchar arg_Event,
    guint arg_State)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA));
  g_signal_emit (instance,
      call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_DTMFChangeRequested],
      0,
      arg_Event,
      arg_State);
}

static inline void
tp_svc_call_content_interface_media_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[7] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{ua{sv}}", 0, NULL, NULL }, /* RemoteMediaDescriptions */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "a{ua{sv}}", 0, NULL, NULL }, /* LocalMediaDescriptions */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(oa{sv})", 0, NULL, NULL }, /* MediaDescriptionOffer */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Packetization */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "y", 0, NULL, NULL }, /* CurrentDTMFEvent */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* CurrentDTMFState */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_interface_media_get_type (),
      &_tp_svc_call_content_interface_media_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content.Interface.Media");
  properties[0].name = g_quark_from_static_string ("RemoteMediaDescriptions");
  properties[0].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  properties[1].name = g_quark_from_static_string ("LocalMediaDescriptions");
  properties[1].type = (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE))));
  properties[2].name = g_quark_from_static_string ("MediaDescriptionOffer");
  properties[2].type = (dbus_g_type_get_struct ("GValueArray", DBUS_TYPE_G_OBJECT_PATH, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)), G_TYPE_INVALID));
  properties[3].name = g_quark_from_static_string ("Packetization");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("CurrentDTMFEvent");
  properties[4].type = G_TYPE_UCHAR;
  properties[5].name = g_quark_from_static_string ("CurrentDTMFState");
  properties[5].type = G_TYPE_UINT;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA, &interface);

  call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_NewMediaDescriptionOffer] =
  g_signal_new ("new-media-description-offer",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      DBUS_TYPE_G_OBJECT_PATH,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

  call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_MediaDescriptionOfferDone] =
  g_signal_new ("media-description-offer-done",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_LocalMediaDescriptionChanged] =
  g_signal_new ("local-media-description-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)));

  call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_RemoteMediaDescriptionsChanged] =
  g_signal_new ("remote-media-descriptions-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_map ("GHashTable", G_TYPE_UINT, (dbus_g_type_get_map ("GHashTable", G_TYPE_STRING, G_TYPE_VALUE)))));

  call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_MediaDescriptionsRemoved] =
  g_signal_new ("media-descriptions-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      DBUS_TYPE_G_UINT_ARRAY);

  call_content_interface_media_signals[SIGNAL_CALL_CONTENT_INTERFACE_MEDIA_DTMFChangeRequested] =
  g_signal_new ("d-tm-fchange-requested",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      2,
      G_TYPE_UCHAR,
      G_TYPE_UINT);

}
static void
tp_svc_call_content_interface_media_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_interface_media_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_interface_media_methods[] = {
  { (GCallback) tp_svc_call_content_interface_media_update_local_media_description, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_call_content_interface_media_acknowledge_dtmf_change, g_cclosure_marshal_generic, 112 },
  { (GCallback) tp_svc_call_content_interface_media_fail, g_cclosure_marshal_generic, 213 },
};

static const DBusGObjectInfo _tp_svc_call_content_interface_media_object_info = {
  0,
  _tp_svc_call_content_interface_media_methods,
  3,
"org.freedesktop.Telepathy.Call1.Content.Interface.Media\0UpdateLocalMediaDescription\0A\0MediaDescription\0I\0a{sv}\0\0org.freedesktop.Telepathy.Call1.Content.Interface.Media\0AcknowledgeDTMFChange\0A\0Event\0I\0y\0State\0I\0u\0\0org.freedesktop.Telepathy.Call1.Content.Interface.Media\0Fail\0A\0Reason\0I\0(uuss)\0\0\0",
"org.freedesktop.Telepathy.Call1.Content.Interface.Media\0NewMediaDescriptionOffer\0org.freedesktop.Telepathy.Call1.Content.Interface.Media\0MediaDescriptionOfferDone\0org.freedesktop.Telepathy.Call1.Content.Interface.Media\0LocalMediaDescriptionChanged\0org.freedesktop.Telepathy.Call1.Content.Interface.Media\0RemoteMediaDescriptionsChanged\0org.freedesktop.Telepathy.Call1.Content.Interface.Media\0MediaDescriptionsRemoved\0org.freedesktop.Telepathy.Call1.Content.Interface.Media\0DTMFChangeRequested\0\0",
"\0\0",
};

static const DBusGObjectInfo _tp_svc_call_content_interface_video_control_object_info;

struct _TpSvcCallContentInterfaceVideoControlClass {
    GTypeInterface parent_class;
};

enum {
    SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_KeyFrameRequested,
    SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_VideoResolutionChanged,
    SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_BitrateChanged,
    SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_FramerateChanged,
    SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_MTUChanged,
    N_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_SIGNALS
};
static guint call_content_interface_video_control_signals[N_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_SIGNALS] = {0};

static void tp_svc_call_content_interface_video_control_base_init (gpointer klass);

GType
tp_svc_call_content_interface_video_control_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcCallContentInterfaceVideoControlClass),
        tp_svc_call_content_interface_video_control_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcCallContentInterfaceVideoControl", &info, 0);
    }

  return type;
}

void
tp_svc_call_content_interface_video_control_emit_key_frame_requested (gpointer instance)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL));
  g_signal_emit (instance,
      call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_KeyFrameRequested],
      0);
}

void
tp_svc_call_content_interface_video_control_emit_video_resolution_changed (gpointer instance,
    const GValueArray *arg_NewResolution)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL));
  g_signal_emit (instance,
      call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_VideoResolutionChanged],
      0,
      arg_NewResolution);
}

void
tp_svc_call_content_interface_video_control_emit_bitrate_changed (gpointer instance,
    guint arg_NewBitrate)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL));
  g_signal_emit (instance,
      call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_BitrateChanged],
      0,
      arg_NewBitrate);
}

void
tp_svc_call_content_interface_video_control_emit_framerate_changed (gpointer instance,
    guint arg_NewFramerate)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL));
  g_signal_emit (instance,
      call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_FramerateChanged],
      0,
      arg_NewFramerate);
}

void
tp_svc_call_content_interface_video_control_emit_mtu_changed (gpointer instance,
    guint arg_NewMTU)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL));
  g_signal_emit (instance,
      call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_MTUChanged],
      0,
      arg_NewMTU);
}

static inline void
tp_svc_call_content_interface_video_control_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  static TpDBusPropertiesMixinPropInfo properties[6] = {
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "(uu)", 0, NULL, NULL }, /* VideoResolution */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Bitrate */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* Framerate */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "u", 0, NULL, NULL }, /* MTU */
      { 0, TP_DBUS_PROPERTIES_MIXIN_FLAG_READ, "b", 0, NULL, NULL }, /* ManualKeyFrames */
      { 0, 0, NULL, 0, NULL, NULL }
  };
  static TpDBusPropertiesMixinIfaceInfo interface =
      { 0, properties, NULL, NULL };

  dbus_g_object_type_install_info (tp_svc_call_content_interface_video_control_get_type (),
      &_tp_svc_call_content_interface_video_control_object_info);

  interface.dbus_interface = g_quark_from_static_string ("org.freedesktop.Telepathy.Call1.Content.Interface.VideoControl");
  properties[0].name = g_quark_from_static_string ("VideoResolution");
  properties[0].type = (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID));
  properties[1].name = g_quark_from_static_string ("Bitrate");
  properties[1].type = G_TYPE_UINT;
  properties[2].name = g_quark_from_static_string ("Framerate");
  properties[2].type = G_TYPE_UINT;
  properties[3].name = g_quark_from_static_string ("MTU");
  properties[3].type = G_TYPE_UINT;
  properties[4].name = g_quark_from_static_string ("ManualKeyFrames");
  properties[4].type = G_TYPE_BOOLEAN;
  tp_svc_interface_set_dbus_properties_info (TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL, &interface);

  call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_KeyFrameRequested] =
  g_signal_new ("key-frame-requested",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      0);

  call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_VideoResolutionChanged] =
  g_signal_new ("video-resolution-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      (dbus_g_type_get_struct ("GValueArray", G_TYPE_UINT, G_TYPE_UINT, G_TYPE_INVALID)));

  call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_BitrateChanged] =
  g_signal_new ("bitrate-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_FramerateChanged] =
  g_signal_new ("framerate-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

  call_content_interface_video_control_signals[SIGNAL_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_MTUChanged] =
  g_signal_new ("m-tu-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      1,
      G_TYPE_UINT);

}
static void
tp_svc_call_content_interface_video_control_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_call_content_interface_video_control_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_call_content_interface_video_control_methods[] = {
  { NULL, NULL, 0 }
};

static const DBusGObjectInfo _tp_svc_call_content_interface_video_control_object_info = {
  0,
  _tp_svc_call_content_interface_video_control_methods,
  0,
"\0",
"org.freedesktop.Telepathy.Call1.Content.Interface.VideoControl\0KeyFrameRequested\0org.freedesktop.Telepathy.Call1.Content.Interface.VideoControl\0VideoResolutionChanged\0org.freedesktop.Telepathy.Call1.Content.Interface.VideoControl\0BitrateChanged\0org.freedesktop.Telepathy.Call1.Content.Interface.VideoControl\0FramerateChanged\0org.freedesktop.Telepathy.Call1.Content.Interface.VideoControl\0MTUChanged\0\0",
"\0\0",
};


