#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcMediaSessionHandler TpSvcMediaSessionHandler;

typedef struct _TpSvcMediaSessionHandlerClass TpSvcMediaSessionHandlerClass;

GType tp_svc_media_session_handler_get_type (void);
#define TP_TYPE_SVC_MEDIA_SESSION_HANDLER \
  (tp_svc_media_session_handler_get_type ())
#define TP_SVC_MEDIA_SESSION_HANDLER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_MEDIA_SESSION_HANDLER, TpSvcMediaSessionHandler))
#define TP_IS_SVC_MEDIA_SESSION_HANDLER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_MEDIA_SESSION_HANDLER))
#define TP_SVC_MEDIA_SESSION_HANDLER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_MEDIA_SESSION_HANDLER, TpSvcMediaSessionHandlerClass))


typedef void (*tp_svc_media_session_handler_error_impl) (TpSvcMediaSessionHandler *self,
    guint in_Error_Code,
    const gchar *in_Message,
    DBusGMethodInvocation *context);
void tp_svc_media_session_handler_implement_error (TpSvcMediaSessionHandlerClass *klass, tp_svc_media_session_handler_error_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_media_session_handler_return_from_error (DBusGMethodInvocation *context);
static inline void
tp_svc_media_session_handler_return_from_error (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

typedef void (*tp_svc_media_session_handler_ready_impl) (TpSvcMediaSessionHandler *self,
    DBusGMethodInvocation *context);
void tp_svc_media_session_handler_implement_ready (TpSvcMediaSessionHandlerClass *klass, tp_svc_media_session_handler_ready_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_media_session_handler_return_from_ready (DBusGMethodInvocation *context);
static inline void
tp_svc_media_session_handler_return_from_ready (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}

void tp_svc_media_session_handler_emit_new_stream_handler (gpointer instance,
    const gchar *arg_Stream_Handler,
    guint arg_ID,
    guint arg_Media_Type,
    guint arg_Direction);


G_END_DECLS
