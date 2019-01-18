#ifndef TP_GEN_TP_CLI_CLIENT_H_INCLUDED
#define TP_GEN_TP_CLI_CLIENT_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_client_approver_callback_for_add_dispatch_operation) (TpClient *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_client_approver_call_add_dispatch_operation (TpClient *proxy,
    gint timeout_ms,
    const GPtrArray *in_Channels,
    const gchar *in_DispatchOperation,
    GHashTable *in_Properties,
    tp_cli_client_approver_callback_for_add_dispatch_operation callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_client_handler_callback_for_handle_channels) (TpClient *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_client_handler_call_handle_channels (TpClient *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    const gchar *in_Connection,
    const GPtrArray *in_Channels,
    const GPtrArray *in_Requests_Satisfied,
    guint64 in_User_Action_Time,
    GHashTable *in_Handler_Info,
    tp_cli_client_handler_callback_for_handle_channels callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_client_interface_requests_callback_for_add_request) (TpClient *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_client_interface_requests_call_add_request (TpClient *proxy,
    gint timeout_ms,
    const gchar *in_Request,
    GHashTable *in_Properties,
    tp_cli_client_interface_requests_callback_for_add_request callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_client_interface_requests_callback_for_remove_request) (TpClient *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_client_interface_requests_call_remove_request (TpClient *proxy,
    gint timeout_ms,
    const gchar *in_Request,
    const gchar *in_Error,
    const gchar *in_Message,
    tp_cli_client_interface_requests_callback_for_remove_request callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_client_observer_callback_for_observe_channels) (TpClient *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_client_observer_call_observe_channels (TpClient *proxy,
    gint timeout_ms,
    const gchar *in_Account,
    const gchar *in_Connection,
    const GPtrArray *in_Channels,
    const gchar *in_Dispatch_Operation,
    const GPtrArray *in_Requests_Satisfied,
    GHashTable *in_Observer_Info,
    tp_cli_client_observer_callback_for_observe_channels callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_CLIENT_H_INCLUDED) */
