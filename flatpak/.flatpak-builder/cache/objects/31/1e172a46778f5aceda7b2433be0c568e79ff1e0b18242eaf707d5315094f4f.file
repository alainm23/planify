#include <glib-object.h>
#include <dbus/dbus-glib.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-properties-mixin.h>


G_BEGIN_DECLS

typedef struct _TpSvcChannelDispatcher TpSvcChannelDispatcher;

typedef struct _TpSvcChannelDispatcherClass TpSvcChannelDispatcherClass;

GType tp_svc_channel_dispatcher_get_type (void);
#define TP_TYPE_SVC_CHANNEL_DISPATCHER \
  (tp_svc_channel_dispatcher_get_type ())
#define TP_SVC_CHANNEL_DISPATCHER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER, TpSvcChannelDispatcher))
#define TP_IS_SVC_CHANNEL_DISPATCHER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER))
#define TP_SVC_CHANNEL_DISPATCHER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER, TpSvcChannelDispatcherClass))


typedef void (*tp_svc_channel_dispatcher_create_channel_impl) (TpSvcChannelDispatcher *self,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    DBusGMethodInvocation *context);
void tp_svc_channel_dispatcher_implement_create_channel (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_create_channel_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_channel_dispatcher_return_from_create_channel (DBusGMethodInvocation *context,
    const gchar *out_Request);
static inline void
tp_svc_channel_dispatcher_return_from_create_channel (DBusGMethodInvocation *context,
    const gchar *out_Request)
{
  dbus_g_method_return (context,
      out_Request);
}

typedef void (*tp_svc_channel_dispatcher_ensure_channel_impl) (TpSvcChannelDispatcher *self,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    DBusGMethodInvocation *context);
void tp_svc_channel_dispatcher_implement_ensure_channel (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_ensure_channel_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_channel_dispatcher_return_from_ensure_channel (DBusGMethodInvocation *context,
    const gchar *out_Request);
static inline void
tp_svc_channel_dispatcher_return_from_ensure_channel (DBusGMethodInvocation *context,
    const gchar *out_Request)
{
  dbus_g_method_return (context,
      out_Request);
}

typedef void (*tp_svc_channel_dispatcher_create_channel_with_hints_impl) (TpSvcChannelDispatcher *self,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    GHashTable *in_Hints,
    DBusGMethodInvocation *context);
void tp_svc_channel_dispatcher_implement_create_channel_with_hints (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_create_channel_with_hints_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_channel_dispatcher_return_from_create_channel_with_hints (DBusGMethodInvocation *context,
    const gchar *out_Request);
static inline void
tp_svc_channel_dispatcher_return_from_create_channel_with_hints (DBusGMethodInvocation *context,
    const gchar *out_Request)
{
  dbus_g_method_return (context,
      out_Request);
}

typedef void (*tp_svc_channel_dispatcher_ensure_channel_with_hints_impl) (TpSvcChannelDispatcher *self,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    GHashTable *in_Hints,
    DBusGMethodInvocation *context);
void tp_svc_channel_dispatcher_implement_ensure_channel_with_hints (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_ensure_channel_with_hints_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_channel_dispatcher_return_from_ensure_channel_with_hints (DBusGMethodInvocation *context,
    const gchar *out_Request);
static inline void
tp_svc_channel_dispatcher_return_from_ensure_channel_with_hints (DBusGMethodInvocation *context,
    const gchar *out_Request)
{
  dbus_g_method_return (context,
      out_Request);
}

typedef void (*tp_svc_channel_dispatcher_delegate_channels_impl) (TpSvcChannelDispatcher *self,
    const GPtrArray *in_Channels,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    DBusGMethodInvocation *context);
void tp_svc_channel_dispatcher_implement_delegate_channels (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_delegate_channels_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_channel_dispatcher_return_from_delegate_channels (DBusGMethodInvocation *context,
    const GPtrArray *out_Delegated,
    GHashTable *out_Not_Delegated);
static inline void
tp_svc_channel_dispatcher_return_from_delegate_channels (DBusGMethodInvocation *context,
    const GPtrArray *out_Delegated,
    GHashTable *out_Not_Delegated)
{
  dbus_g_method_return (context,
      out_Delegated,
      out_Not_Delegated);
}

typedef void (*tp_svc_channel_dispatcher_present_channel_impl) (TpSvcChannelDispatcher *self,
    const gchar *in_Channel,
    gint64 in_User_Action_Time,
    DBusGMethodInvocation *context);
void tp_svc_channel_dispatcher_implement_present_channel (TpSvcChannelDispatcherClass *klass, tp_svc_channel_dispatcher_present_channel_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_channel_dispatcher_return_from_present_channel (DBusGMethodInvocation *context);
static inline void
tp_svc_channel_dispatcher_return_from_present_channel (DBusGMethodInvocation *context)
{
  dbus_g_method_return (context);
}


typedef struct _TpSvcChannelDispatcherInterfaceMessages1 TpSvcChannelDispatcherInterfaceMessages1;

typedef struct _TpSvcChannelDispatcherInterfaceMessages1Class TpSvcChannelDispatcherInterfaceMessages1Class;

GType tp_svc_channel_dispatcher_interface_messages1_get_type (void);
#define TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1 \
  (tp_svc_channel_dispatcher_interface_messages1_get_type ())
#define TP_SVC_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1, TpSvcChannelDispatcherInterfaceMessages1))
#define TP_IS_SVC_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1))
#define TP_SVC_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_MESSAGES1, TpSvcChannelDispatcherInterfaceMessages1Class))


typedef void (*tp_svc_channel_dispatcher_interface_messages1_send_message_impl) (TpSvcChannelDispatcherInterfaceMessages1 *self,
    const gchar *in_Account,
    const gchar *in_Target_ID,
    const GPtrArray *in_Message,
    guint in_Flags,
    DBusGMethodInvocation *context);
void tp_svc_channel_dispatcher_interface_messages1_implement_send_message (TpSvcChannelDispatcherInterfaceMessages1Class *klass, tp_svc_channel_dispatcher_interface_messages1_send_message_impl impl);
static inline
/* this comment is to stop gtkdoc realising this is static */
void tp_svc_channel_dispatcher_interface_messages1_return_from_send_message (DBusGMethodInvocation *context,
    const gchar *out_Token);
static inline void
tp_svc_channel_dispatcher_interface_messages1_return_from_send_message (DBusGMethodInvocation *context,
    const gchar *out_Token)
{
  dbus_g_method_return (context,
      out_Token);
}


typedef struct _TpSvcChannelDispatcherInterfaceOperationList TpSvcChannelDispatcherInterfaceOperationList;

typedef struct _TpSvcChannelDispatcherInterfaceOperationListClass TpSvcChannelDispatcherInterfaceOperationListClass;

GType tp_svc_channel_dispatcher_interface_operation_list_get_type (void);
#define TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST \
  (tp_svc_channel_dispatcher_interface_operation_list_get_type ())
#define TP_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST, TpSvcChannelDispatcherInterfaceOperationList))
#define TP_IS_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST))
#define TP_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE((obj), TP_TYPE_SVC_CHANNEL_DISPATCHER_INTERFACE_OPERATION_LIST, TpSvcChannelDispatcherInterfaceOperationListClass))


void tp_svc_channel_dispatcher_interface_operation_list_emit_new_dispatch_operation (gpointer instance,
    const gchar *arg_Dispatch_Operation,
    GHashTable *arg_Properties);
void tp_svc_channel_dispatcher_interface_operation_list_emit_dispatch_operation_finished (gpointer instance,
    const gchar *arg_Dispatch_Operation);


G_END_DECLS
