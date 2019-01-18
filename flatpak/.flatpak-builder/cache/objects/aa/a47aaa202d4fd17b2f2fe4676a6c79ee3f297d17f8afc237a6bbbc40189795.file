#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcDebug TpSvcDebug;

typedef struct _TpSvcDebugClass TpSvcDebugClass;

GType tp_svc_debug_get_type (void);
#define TP_TYPE_SVC_DEBUG \
  (tp_svc_debug_get_type ())
#define TP_SVC_DEBUG(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_DEBUG, TpSvcDebug))
#define TP_IS_SVC_DEBUG(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_DEBUG))
#define TP_SVC_DEBUG_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_DEBUG, TpSvcDebugClass))


typedef void (*tp_svc_debug_get_messages_impl) (TpSvcDebug *self,
    DBusGMethodInvocation *context);
void tp_svc_debug_implement_get_messages (TpSvcDebugClass *klass, tp_svc_debug_get_messages_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_debug_return_from_get_messages (DBusGMethodInvocation *context,
    const GPtrArray *out_Messages);
static inline void
tp_svc_debug_return_from_get_messages (DBusGMethodInvocation *context,
    const GPtrArray *out_Messages)
{
  dbus_g_method_return (context,
      out_Messages);
}

void tp_svc_debug_emit_new_debug_message (gpointer instance,
    gdouble arg_time,
    const gchar *arg_domain,
    guint arg_level,
    const gchar *arg_message);


G_END_DECLS
