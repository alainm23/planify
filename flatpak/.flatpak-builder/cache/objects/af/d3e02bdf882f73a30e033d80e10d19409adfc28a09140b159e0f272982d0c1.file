#ifndef TP_GEN_TP_CLI_ACCOUNT_MANAGER_H_INCLUDED
#define TP_GEN_TP_CLI_ACCOUNT_MANAGER_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_account_manager_signal_callback_account_removed) (TpAccountManager *proxy,
    const gchar *arg_Account,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_account_manager_connect_to_account_removed (TpAccountManager *proxy,
    tp_cli_account_manager_signal_callback_account_removed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_account_manager_signal_callback_account_validity_changed) (TpAccountManager *proxy,
    const gchar *arg_Account,
    gboolean arg_Valid,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_account_manager_connect_to_account_validity_changed (TpAccountManager *proxy,
    tp_cli_account_manager_signal_callback_account_validity_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_account_manager_callback_for_create_account) (TpAccountManager *proxy,
    const gchar *out_Account,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_account_manager_call_create_account (TpAccountManager *proxy,
    gint timeout_ms,
    const gchar *in_Connection_Manager,
    const gchar *in_Protocol,
    const gchar *in_Display_Name,
    GHashTable *in_Parameters,
    GHashTable *in_Properties,
    tp_cli_account_manager_callback_for_create_account callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_ACCOUNT_MANAGER_H_INCLUDED) */
