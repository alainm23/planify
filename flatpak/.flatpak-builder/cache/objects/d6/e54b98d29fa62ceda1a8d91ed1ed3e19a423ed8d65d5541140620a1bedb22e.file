#ifndef TP_GEN_TP_CLI_ACCOUNT_H_INCLUDED
#define TP_GEN_TP_CLI_ACCOUNT_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_account_signal_callback_removed) (TpAccount *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_account_connect_to_removed (TpAccount *proxy,
    tp_cli_account_signal_callback_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_account_signal_callback_account_property_changed) (TpAccount *proxy,
    GHashTable *arg_Properties,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_account_connect_to_account_property_changed (TpAccount *proxy,
    tp_cli_account_signal_callback_account_property_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_account_callback_for_remove) (TpAccount *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_account_call_remove (TpAccount *proxy,
    gint timeout_ms,
    tp_cli_account_callback_for_remove callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_account_callback_for_update_parameters) (TpAccount *proxy,
    const gchar **out_Reconnect_Required,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_account_call_update_parameters (TpAccount *proxy,
    gint timeout_ms,
    GHashTable *in_Set,
    const gchar **in_Unset,
    tp_cli_account_callback_for_update_parameters callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_account_callback_for_reconnect) (TpAccount *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_account_call_reconnect (TpAccount *proxy,
    gint timeout_ms,
    tp_cli_account_callback_for_reconnect callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_account_interface_addressing_callback_for_set_uri_scheme_association) (TpAccount *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_account_interface_addressing_call_set_uri_scheme_association (TpAccount *proxy,
    gint timeout_ms,
    const gchar *in_URI_Scheme,
    gboolean in_Association,
    tp_cli_account_interface_addressing_callback_for_set_uri_scheme_association callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


typedef void (*tp_cli_account_interface_avatar_signal_callback_avatar_changed) (TpAccount *proxy,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_account_interface_avatar_connect_to_avatar_changed (TpAccount *proxy,
    tp_cli_account_interface_avatar_signal_callback_avatar_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_ACCOUNT_H_INCLUDED) */
