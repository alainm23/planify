#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcCallStream TpSvcCallStream;

typedef struct _TpSvcCallStreamClass TpSvcCallStreamClass;

GType tp_svc_call_stream_get_type (void);
#define TP_TYPE_SVC_CALL_STREAM \
  (tp_svc_call_stream_get_type ())
#define TP_SVC_CALL_STREAM(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CALL_STREAM, TpSvcCallStream))
#define TP_IS_SVC_CALL_STREAM(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CALL_STREAM))
#define TP_SVC_CALL_STREAM_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CALL_STREAM, TpSvcCallStreamClass))


typedef void (*tp_svc_call_stream_set_sending_impl) (TpSvcCallStream *self,
    gboolean in_Send,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_implement_set_sending (TpSvcCallStreamClass *klass, tp_svc_call_stream_set_sending_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_return_from_set_sending (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_return_from_set_sending (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_request_receiving_impl) (TpSvcCallStream *self,
    guint in_Contact,
    gboolean in_Receive,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_implement_request_receiving (TpSvcCallStreamClass *klass, tp_svc_call_stream_request_receiving_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_return_from_request_receiving (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_return_from_request_receiving (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_call_stream_emit_remote_members_changed (gpointer instance,
    GHashTable *arg_Updates,
    GHashTable *arg_Identifiers,
    const GArray *arg_Removed,
    const GValueArray *arg_Reason);
void tp_svc_call_stream_emit_local_sending_state_changed (gpointer instance,
    guint arg_State,
    const GValueArray *arg_Reason);

typedef struct _TpSvcCallStreamInterfaceMedia TpSvcCallStreamInterfaceMedia;

typedef struct _TpSvcCallStreamInterfaceMediaClass TpSvcCallStreamInterfaceMediaClass;

GType tp_svc_call_stream_interface_media_get_type (void);
#define TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA \
  (tp_svc_call_stream_interface_media_get_type ())
#define TP_SVC_CALL_STREAM_INTERFACE_MEDIA(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA, TpSvcCallStreamInterfaceMedia))
#define TP_IS_SVC_CALL_STREAM_INTERFACE_MEDIA(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA))
#define TP_SVC_CALL_STREAM_INTERFACE_MEDIA_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CALL_STREAM_INTERFACE_MEDIA, TpSvcCallStreamInterfaceMediaClass))


typedef void (*tp_svc_call_stream_interface_media_complete_sending_state_change_impl) (TpSvcCallStreamInterfaceMedia *self,
    guint in_State,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_interface_media_implement_complete_sending_state_change (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_complete_sending_state_change_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_interface_media_return_from_complete_sending_state_change (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_interface_media_return_from_complete_sending_state_change (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_interface_media_report_sending_failure_impl) (TpSvcCallStreamInterfaceMedia *self,
    guint in_Reason,
    const gchar *in_Error,
    const gchar *in_Message,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_interface_media_implement_report_sending_failure (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_report_sending_failure_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_interface_media_return_from_report_sending_failure (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_interface_media_return_from_report_sending_failure (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_interface_media_complete_receiving_state_change_impl) (TpSvcCallStreamInterfaceMedia *self,
    guint in_State,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_interface_media_implement_complete_receiving_state_change (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_complete_receiving_state_change_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_interface_media_return_from_complete_receiving_state_change (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_interface_media_return_from_complete_receiving_state_change (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_interface_media_report_receiving_failure_impl) (TpSvcCallStreamInterfaceMedia *self,
    guint in_Reason,
    const gchar *in_Error,
    const gchar *in_Message,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_interface_media_implement_report_receiving_failure (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_report_receiving_failure_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_interface_media_return_from_report_receiving_failure (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_interface_media_return_from_report_receiving_failure (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_interface_media_set_credentials_impl) (TpSvcCallStreamInterfaceMedia *self,
    const gchar *in_Username,
    const gchar *in_Password,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_interface_media_implement_set_credentials (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_set_credentials_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_interface_media_return_from_set_credentials (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_interface_media_return_from_set_credentials (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_interface_media_add_candidates_impl) (TpSvcCallStreamInterfaceMedia *self,
    const GPtrArray *in_Candidates,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_interface_media_implement_add_candidates (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_add_candidates_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_interface_media_return_from_add_candidates (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_interface_media_return_from_add_candidates (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_interface_media_finish_initial_candidates_impl) (TpSvcCallStreamInterfaceMedia *self,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_interface_media_implement_finish_initial_candidates (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_finish_initial_candidates_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_interface_media_return_from_finish_initial_candidates (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_interface_media_return_from_finish_initial_candidates (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_call_stream_interface_media_fail_impl) (TpSvcCallStreamInterfaceMedia *self,
    const GValueArray *in_Reason,
    DBusGMethodInvocation *context);
void tp_svc_call_stream_interface_media_implement_fail (TpSvcCallStreamInterfaceMediaClass *klass, tp_svc_call_stream_interface_media_fail_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_call_stream_interface_media_return_from_fail (DBusGMethodInvocation *context);
static inline void
tp_svc_call_stream_interface_media_return_from_fail (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_call_stream_interface_media_emit_sending_state_changed (gpointer instance,
    guint arg_State);
void tp_svc_call_stream_interface_media_emit_receiving_state_changed (gpointer instance,
    guint arg_State);
void tp_svc_call_stream_interface_media_emit_local_candidates_added (gpointer instance,
    const GPtrArray *arg_Candidates);
void tp_svc_call_stream_interface_media_emit_local_credentials_changed (gpointer instance,
    const gchar *arg_Username,
    const gchar *arg_Password);
void tp_svc_call_stream_interface_media_emit_relay_info_changed (gpointer instance,
    const GPtrArray *arg_Relay_Info);
void tp_svc_call_stream_interface_media_emit_stun_servers_changed (gpointer instance,
    const GPtrArray *arg_Servers);
void tp_svc_call_stream_interface_media_emit_server_info_retrieved (gpointer instance);
void tp_svc_call_stream_interface_media_emit_endpoints_changed (gpointer instance,
    const GPtrArray *arg_Endpoints_Added,
    const GPtrArray *arg_Endpoints_Removed);
void tp_svc_call_stream_interface_media_emit_ice_restart_requested (gpointer instance);


G_END_DECLS
