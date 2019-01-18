#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcCallContent TpSvcCallContent;

typedef struct _TpSvcCallContentClass TpSvcCallContentClass;

GType tp_svc_call_content_get_type (void);
#define TP_TYPE_SVC_CALL_CONTENT \
  (tp_svc_call_content_get_type ())
#define TP_SVC_CALL_CONTENT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CALL_CONTENT, TpSvcCallContent))
#define TP_IS_SVC_CALL_CONTENT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CALL_CONTENT))
#define TP_SVC_CALL_CONTENT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CALL_CONTENT, TpSvcCallContentClass))


typedef void (*tp_svc_call_content_remove_impl) (TpSvcCallContent *self,
    DBusGMethodInvocation *context);
void tp_svc_call_content_implement_remove (TpSvcCallContentClass *klass, tp_svc_call_content_remove_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_return_from_remove (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_return_from_remove (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_call_content_emit_streams_added (gpointer instance,
    const GPtrArray *arg_Streams);
void tp_svc_call_content_emit_streams_removed (gpointer instance,
    const GPtrArray *arg_Streams,
    const GValueArray *arg_Reason);

typedef struct _TpSvcCallContentInterfaceAudioControl TpSvcCallContentInterfaceAudioControl;

typedef struct _TpSvcCallContentInterfaceAudioControlClass TpSvcCallContentInterfaceAudioControlClass;

GType tp_svc_call_content_interface_audio_control_get_type (void);
#define TP_TYPE_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL \
  (tp_svc_call_content_interface_audio_control_get_type ())
#define TP_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL, TpSvcCallContentInterfaceAudioControl))
#define TP_IS_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL))
#define TP_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_AUDIO_CONTROL, TpSvcCallContentInterfaceAudioControlClass))


typedef void (*tp_svc_call_content_interface_audio_control_report_input_volume_impl) (TpSvcCallContentInterfaceAudioControl *self,
    gint in_Volume,
    DBusGMethodInvocation *context);
void tp_svc_call_content_interface_audio_control_implement_report_input_volume (TpSvcCallContentInterfaceAudioControlClass *klass, tp_svc_call_content_interface_audio_control_report_input_volume_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_interface_audio_control_return_from_report_input_volume (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_interface_audio_control_return_from_report_input_volume (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_content_interface_audio_control_report_output_volume_impl) (TpSvcCallContentInterfaceAudioControl *self,
    gint in_Volume,
    DBusGMethodInvocation *context);
void tp_svc_call_content_interface_audio_control_implement_report_output_volume (TpSvcCallContentInterfaceAudioControlClass *klass, tp_svc_call_content_interface_audio_control_report_output_volume_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_interface_audio_control_return_from_report_output_volume (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_interface_audio_control_return_from_report_output_volume (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}


typedef struct _TpSvcCallContentInterfaceDTMF TpSvcCallContentInterfaceDTMF;

typedef struct _TpSvcCallContentInterfaceDTMFClass TpSvcCallContentInterfaceDTMFClass;

GType tp_svc_call_content_interface_dtmf_get_type (void);
#define TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF \
  (tp_svc_call_content_interface_dtmf_get_type ())
#define TP_SVC_CALL_CONTENT_INTERFACE_DTMF(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF, TpSvcCallContentInterfaceDTMF))
#define TP_IS_SVC_CALL_CONTENT_INTERFACE_DTMF(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF))
#define TP_SVC_CALL_CONTENT_INTERFACE_DTMF_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_DTMF, TpSvcCallContentInterfaceDTMFClass))


typedef void (*tp_svc_call_content_interface_dtmf_start_tone_impl) (TpSvcCallContentInterfaceDTMF *self,
    guchar in_Event,
    DBusGMethodInvocation *context);
void tp_svc_call_content_interface_dtmf_implement_start_tone (TpSvcCallContentInterfaceDTMFClass *klass, tp_svc_call_content_interface_dtmf_start_tone_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_interface_dtmf_return_from_start_tone (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_interface_dtmf_return_from_start_tone (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_content_interface_dtmf_stop_tone_impl) (TpSvcCallContentInterfaceDTMF *self,
    DBusGMethodInvocation *context);
void tp_svc_call_content_interface_dtmf_implement_stop_tone (TpSvcCallContentInterfaceDTMFClass *klass, tp_svc_call_content_interface_dtmf_stop_tone_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_interface_dtmf_return_from_stop_tone (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_interface_dtmf_return_from_stop_tone (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_content_interface_dtmf_multiple_tones_impl) (TpSvcCallContentInterfaceDTMF *self,
    const gchar *in_Tones,
    DBusGMethodInvocation *context);
void tp_svc_call_content_interface_dtmf_implement_multiple_tones (TpSvcCallContentInterfaceDTMFClass *klass, tp_svc_call_content_interface_dtmf_multiple_tones_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_interface_dtmf_return_from_multiple_tones (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_interface_dtmf_return_from_multiple_tones (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_call_content_interface_dtmf_emit_tones_deferred (gpointer instance,
    const gchar *arg_Tones);
void tp_svc_call_content_interface_dtmf_emit_sending_tones (gpointer instance,
    const gchar *arg_Tones);
void tp_svc_call_content_interface_dtmf_emit_stopped_tones (gpointer instance,
    gboolean arg_Cancelled);

typedef struct _TpSvcCallContentInterfaceMedia TpSvcCallContentInterfaceMedia;

typedef struct _TpSvcCallContentInterfaceMediaClass TpSvcCallContentInterfaceMediaClass;

GType tp_svc_call_content_interface_media_get_type (void);
#define TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA \
  (tp_svc_call_content_interface_media_get_type ())
#define TP_SVC_CALL_CONTENT_INTERFACE_MEDIA(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA, TpSvcCallContentInterfaceMedia))
#define TP_IS_SVC_CALL_CONTENT_INTERFACE_MEDIA(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA))
#define TP_SVC_CALL_CONTENT_INTERFACE_MEDIA_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_MEDIA, TpSvcCallContentInterfaceMediaClass))


typedef void (*tp_svc_call_content_interface_media_update_local_media_description_impl) (TpSvcCallContentInterfaceMedia *self,
    GHashTable *in_MediaDescription,
    DBusGMethodInvocation *context);
void tp_svc_call_content_interface_media_implement_update_local_media_description (TpSvcCallContentInterfaceMediaClass *klass, tp_svc_call_content_interface_media_update_local_media_description_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_interface_media_return_from_update_local_media_description (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_interface_media_return_from_update_local_media_description (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_content_interface_media_acknowledge_dtmf_change_impl) (TpSvcCallContentInterfaceMedia *self,
    guchar in_Event,
    guint in_State,
    DBusGMethodInvocation *context);
void tp_svc_call_content_interface_media_implement_acknowledge_dtmf_change (TpSvcCallContentInterfaceMediaClass *klass, tp_svc_call_content_interface_media_acknowledge_dtmf_change_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_interface_media_return_from_acknowledge_dtmf_change (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_interface_media_return_from_acknowledge_dtmf_change (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_content_interface_media_fail_impl) (TpSvcCallContentInterfaceMedia *self,
    const GValueArray *in_Reason,
    DBusGMethodInvocation *context);
void tp_svc_call_content_interface_media_implement_fail (TpSvcCallContentInterfaceMediaClass *klass, tp_svc_call_content_interface_media_fail_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_content_interface_media_return_from_fail (DBusGMethodInvocation *context);
static inline void
tp_svc_call_content_interface_media_return_from_fail (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_call_content_interface_media_emit_new_media_description_offer (gpointer instance,
    const gchar *arg_Media_Description,
    GHashTable *arg_Properties);
void tp_svc_call_content_interface_media_emit_media_description_offer_done (gpointer instance);
void tp_svc_call_content_interface_media_emit_local_media_description_changed (gpointer instance,
    GHashTable *arg_Updated_Media_Description);
void tp_svc_call_content_interface_media_emit_remote_media_descriptions_changed (gpointer instance,
    GHashTable *arg_Updated_Media_Descriptions);
void tp_svc_call_content_interface_media_emit_media_descriptions_removed (gpointer instance,
    const GArray *arg_Removed_Media_Descriptions);
void tp_svc_call_content_interface_media_emit_dtmf_change_requested (gpointer instance,
    guchar arg_Event,
    guint arg_State);

typedef struct _TpSvcCallContentInterfaceVideoControl TpSvcCallContentInterfaceVideoControl;

typedef struct _TpSvcCallContentInterfaceVideoControlClass TpSvcCallContentInterfaceVideoControlClass;

GType tp_svc_call_content_interface_video_control_get_type (void);
#define TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL \
  (tp_svc_call_content_interface_video_control_get_type ())
#define TP_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL, TpSvcCallContentInterfaceVideoControl))
#define TP_IS_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL))
#define TP_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CALL_CONTENT_INTERFACE_VIDEO_CONTROL, TpSvcCallContentInterfaceVideoControlClass))


void tp_svc_call_content_interface_video_control_emit_key_frame_requested (gpointer instance);
void tp_svc_call_content_interface_video_control_emit_video_resolution_changed (gpointer instance,
    const GValueArray *arg_NewResolution);
void tp_svc_call_content_interface_video_control_emit_bitrate_changed (gpointer instance,
    guint arg_NewBitrate);
void tp_svc_call_content_interface_video_control_emit_framerate_changed (gpointer instance,
    guint arg_NewFramerate);
void tp_svc_call_content_interface_video_control_emit_mtu_changed (gpointer instance,
    guint arg_NewMTU);


G_END_DECLS
