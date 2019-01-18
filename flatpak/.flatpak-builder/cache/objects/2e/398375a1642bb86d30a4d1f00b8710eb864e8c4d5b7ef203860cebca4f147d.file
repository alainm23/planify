#include "_gen/tp-svc-media-session-handler.h"

static const DBusGObjectInfo _tp_svc_media_session_handler_object_info;

struct _TpSvcMediaSessionHandlerClass {
    GTypeInterface parent_class;
    tp_svc_media_session_handler_error_impl error_cb;
    tp_svc_media_session_handler_ready_impl ready_cb;
};

enum {
    SIGNAL_MEDIA_SESSION_HANDLER_NewStreamHandler,
    N_MEDIA_SESSION_HANDLER_SIGNALS
};
static guint media_session_handler_signals[N_MEDIA_SESSION_HANDLER_SIGNALS] = {0};

static void tp_svc_media_session_handler_base_init (gpointer klass);

GType
tp_svc_media_session_handler_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpSvcMediaSessionHandlerClass),
        tp_svc_media_session_handler_base_init, /* base_init */
        NULL, /* base_finalize */
        NULL, /* class_init */
        NULL, /* class_finalize */
        NULL, /* class_data */
        0,
        0, /* n_preallocs */
        NULL /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpSvcMediaSessionHandler", &info, 0);
    }

  return type;
}

static void
tp_svc_media_session_handler_error (TpSvcMediaSessionHandler *self,
    guint in_Error_Code,
    const gchar *in_Message,
    DBusGMethodInvocation *context)
{
  tp_svc_media_session_handler_error_impl impl = (TP_SVC_MEDIA_SESSION_HANDLER_GET_CLASS (self)->error_cb);

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
tp_svc_media_session_handler_implement_error (TpSvcMediaSessionHandlerClass *klass, tp_svc_media_session_handler_error_impl impl)
{
  klass->error_cb = impl;
}

static void
tp_svc_media_session_handler_ready (TpSvcMediaSessionHandler *self,
    DBusGMethodInvocation *context)
{
  tp_svc_media_session_handler_ready_impl impl = (TP_SVC_MEDIA_SESSION_HANDLER_GET_CLASS (self)->ready_cb);

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
tp_svc_media_session_handler_implement_ready (TpSvcMediaSessionHandlerClass *klass, tp_svc_media_session_handler_ready_impl impl)
{
  klass->ready_cb = impl;
}

void
tp_svc_media_session_handler_emit_new_stream_handler (gpointer instance,
    const gchar *arg_Stream_Handler,
    guint arg_ID,
    guint arg_Media_Type,
    guint arg_Direction)
{
  g_assert (instance != NULL);
  g_assert (G_TYPE_CHECK_INSTANCE_TYPE (instance, TP_TYPE_SVC_MEDIA_SESSION_HANDLER));
  g_signal_emit (instance,
      media_session_handler_signals[SIGNAL_MEDIA_SESSION_HANDLER_NewStreamHandler],
      0,
      arg_Stream_Handler,
      arg_ID,
      arg_Media_Type,
      arg_Direction);
}

static inline void
tp_svc_media_session_handler_base_init_once (gpointer klass G_GNUC_UNUSED)
{
  dbus_g_object_type_install_info (tp_svc_media_session_handler_get_type (),
      &_tp_svc_media_session_handler_object_info);

  media_session_handler_signals[SIGNAL_MEDIA_SESSION_HANDLER_NewStreamHandler] =
  g_signal_new ("new-stream-handler",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST|G_SIGNAL_DETAILED,
      0,
      NULL, NULL,
      g_cclosure_marshal_generic,
      G_TYPE_NONE,
      4,
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_UINT,
      G_TYPE_UINT,
      G_TYPE_UINT);

}
static void
tp_svc_media_session_handler_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      initialized = TRUE;
      tp_svc_media_session_handler_base_init_once (klass);
    }
}
static const DBusGMethodInfo _tp_svc_media_session_handler_methods[] = {
  { (GCallback) tp_svc_media_session_handler_error, g_cclosure_marshal_generic, 0 },
  { (GCallback) tp_svc_media_session_handler_ready, g_cclosure_marshal_generic, 83 },
};

static const DBusGObjectInfo _tp_svc_media_session_handler_object_info = {
  0,
  _tp_svc_media_session_handler_methods,
  2,
"org.freedesktop.Telepathy.Media.SessionHandler\0Error\0A\0Error_Code\0I\0u\0Message\0I\0s\0\0org.freedesktop.Telepathy.Media.SessionHandler\0Ready\0A\0\0\0",
"org.freedesktop.Telepathy.Media.SessionHandler\0NewStreamHandler\0\0",
"\0\0",
};


