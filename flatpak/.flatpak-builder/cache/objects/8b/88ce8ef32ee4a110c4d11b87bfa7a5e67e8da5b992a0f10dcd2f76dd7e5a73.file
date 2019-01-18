#ifndef TP_GEN_TP_CLI_CHANNEL_DISPATCHER_H_INCLUDED
#define TP_GEN_TP_CLI_CHANNEL_DISPATCHER_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_channel_dispatcher_callback_for_create_channel) (TpChannelDispatcher *proxy,
    const gchar *out_Request,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_channel_dispatcher_call_create_channel (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    tp_cli_channel_dispatcher_callback_for_create_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_channel_dispatcher_callback_for_ensure_channel) (TpChannelDispatcher *proxy,
    const gchar *out_Request,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_channel_dispatcher_call_ensure_channel (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    tp_cli_channel_dispatcher_callback_for_ensure_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_channel_dispatcher_callback_for_create_channel_with_hints) (TpChannelDispatcher *proxy,
    const gchar *out_Request,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_channel_dispatcher_call_create_channel_with_hints (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    GHashTable *in_Hints,
    tp_cli_channel_dispatcher_callback_for_create_channel_with_hints callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_channel_dispatcher_callback_for_ensure_channel_with_hints) (TpChannelDispatcher *proxy,
    const gchar *out_Request,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_channel_dispatcher_call_ensure_channel_with_hints (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    GHashTable *in_Requested_Properties,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    GHashTable *in_Hints,
    tp_cli_channel_dispatcher_callback_for_ensure_channel_with_hints callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_channel_dispatcher_callback_for_delegate_channels) (TpChannelDispatcher *proxy,
    const GPtrArray *out_Delegated,
    GHashTable *out_Not_Delegated,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_channel_dispatcher_call_delegate_channels (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const GPtrArray *in_Channels,
    gint64 in_User_Action_Time,
    const gchar *in_Preferred_Handler,
    tp_cli_channel_dispatcher_callback_for_delegate_channels callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_channel_dispatcher_callback_for_present_channel) (TpChannelDispatcher *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_channel_dispatcher_call_present_channel (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Channel,
    gint64 in_User_Action_Time,
    tp_cli_channel_dispatcher_callback_for_present_channel callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_channel_dispatcher_interface_messages1_callback_for_send_message) (TpChannelDispatcher *proxy,
    const gchar *out_Token,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_channel_dispatcher_interface_messages1_call_send_message (TpChannelDispatcher *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    const gchar *in_Target_ID,
    const GPtrArray *in_Message,
    guint in_Flags,
    tp_cli_channel_dispatcher_interface_messages1_callback_for_send_message callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_channel_dispatcher_interface_operation_list_signal_callback_new_dispatch_operation) (TpChannelDispatcher *proxy,
    const gchar *arg_Dispatch_Operation,
    GHashTable *arg_Properties,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_channel_dispatcher_interface_operation_list_connect_to_new_dispatch_operation (TpChannelDispatcher *proxy,
    tp_cli_channel_dispatcher_interface_operation_list_signal_callback_new_dispatch_operation callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_channel_dispatcher_interface_operation_list_signal_callback_dispatch_operation_finished) (TpChannelDispatcher *proxy,
    const gchar *arg_Dispatch_Operation,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_channel_dispatcher_interface_operation_list_connect_to_dispatch_operation_finished (TpChannelDispatcher *proxy,
    tp_cli_channel_dispatcher_interface_operation_list_signal_callback_dispatch_operation_finished callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_CHANNEL_DISPATCHER_H_INCLUDED) */
