#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcConnectionManager TpSvcConnectionManager;

typedef struct _TpSvcConnectionManagerClass TpSvcConnectionManagerClass;

GType tp_svc_connection_manager_get_type (void);
#define TP_TYPE_SVC_CONNECTION_MANAGER \
  (tp_svc_connection_manager_get_type ())
#define TP_SVC_CONNECTION_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CONNECTION_MANAGER, TpSvcConnectionManager))
#define TP_IS_SVC_CONNECTION_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CONNECTION_MANAGER))
#define TP_SVC_CONNECTION_MANAGER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CONNECTION_MANAGER, TpSvcConnectionManagerClass))


typedef void (*tp_svc_connection_manager_get_parameters_impl) (TpSvcConnectionManager *self,
    const gchar *in_Protocol,
    DBusGMethodInvocation *context);
void tp_svc_connection_manager_implement_get_parameters (TpSvcConnectionManagerClass *klass, tp_svc_connection_manager_get_parameters_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_manager_return_from_get_parameters (DBusGMethodInvocation *context,
    const GPtrArray *out_Parameters);
static inline void
tp_svc_connection_manager_return_from_get_parameters (DBusGMethodInvocation *context,
    const GPtrArray *out_Parameters)
{
  dbus_g_method_return (context,
      out_Parameters);
}

typedef void (*tp_svc_connection_manager_list_protocols_impl) (TpSvcConnectionManager *self,
    DBusGMethodInvocation *context);
void tp_svc_connection_manager_implement_list_protocols (TpSvcConnectionManagerClass *klass, tp_svc_connection_manager_list_protocols_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_manager_return_from_list_protocols (DBusGMethodInvocation *context,
    const gchar **out_Protocols);
static inline void
tp_svc_connection_manager_return_from_list_protocols (DBusGMethodInvocation *context,
    const gchar **out_Protocols)
{
  dbus_g_method_return (context,
      out_Protocols);
}

typedef void (*tp_svc_connection_manager_request_connection_impl) (TpSvcConnectionManager *self,
    const gchar *in_Protocol,
    GHashTable *in_Parameters,
    DBusGMethodInvocation *context);
void tp_svc_connection_manager_implement_request_connection (TpSvcConnectionManagerClass *klass, tp_svc_connection_manager_request_connection_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_connection_manager_return_from_request_connection (DBusGMethodInvocation *context,
    const gchar *out_Bus_Name,
    const gchar *out_Object_Path);
static inline void
tp_svc_connection_manager_return_from_request_connection (DBusGMethodInvocation *context,
    const gchar *out_Bus_Name,
    const gchar *out_Object_Path)
{
  dbus_g_method_return (context,
      out_Bus_Name,
      out_Object_Path);
}

void tp_svc_connection_manager_emit_new_connection (gpointer instance,
    const gchar *arg_Bus_Name,
    const gchar *arg_Object_Path,
    const gchar *arg_Protocol);


G_END_DECLS
