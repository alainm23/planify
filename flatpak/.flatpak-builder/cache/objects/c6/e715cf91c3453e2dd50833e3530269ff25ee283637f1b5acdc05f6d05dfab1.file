#ifndef TP_GEN_TP_CLI_DBUS_DAEMON_H_INCLUDED
#define TP_GEN_TP_CLI_DBUS_DAEMON_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_dbus_daemon_signal_callback_name_owner_changed) (TpDBusDaemon *proxy,
    const gchar *arg0,
    const gchar *arg1,
    const gchar *arg2,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_dbus_daemon_connect_to_name_owner_changed (TpDBusDaemon *proxy,
    tp_cli_dbus_daemon_signal_callback_name_owner_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_dbus_daemon_signal_callback_name_lost) (TpDBusDaemon *proxy,
    const gchar *arg0,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_dbus_daemon_connect_to_name_lost (TpDBusDaemon *proxy,
    tp_cli_dbus_daemon_signal_callback_name_lost callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_dbus_daemon_signal_callback_name_acquired) (TpDBusDaemon *proxy,
    const gchar *arg0,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_dbus_daemon_connect_to_name_acquired (TpDBusDaemon *proxy,
    tp_cli_dbus_daemon_signal_callback_name_acquired callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_dbus_daemon_callback_for_hello) (TpDBusDaemon *proxy,
    const gchar *out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_hello (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_hello callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_hello (TpDBusDaemon *proxy,
    gint timeout_ms,
    gchar **out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_request_name) (TpDBusDaemon *proxy,
    guint out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_request_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint in1,
    tp_cli_dbus_daemon_callback_for_request_name callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_request_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint in1,
    guint *out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_release_name) (TpDBusDaemon *proxy,
    guint out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_release_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_release_name callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_release_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint *out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_start_service_by_name) (TpDBusDaemon *proxy,
    guint out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_start_service_by_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint in1,
    tp_cli_dbus_daemon_callback_for_start_service_by_name callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_start_service_by_name (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint in1,
    guint *out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_name_has_owner) (TpDBusDaemon *proxy,
    gboolean out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_name_has_owner (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_name_has_owner callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_name_has_owner (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    gboolean *out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_list_names) (TpDBusDaemon *proxy,
    const gchar **out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_list_names (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_list_names callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_list_names (TpDBusDaemon *proxy,
    gint timeout_ms,
    gchar ***out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_list_activatable_names) (TpDBusDaemon *proxy,
    const gchar **out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_list_activatable_names (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_list_activatable_names callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_list_activatable_names (TpDBusDaemon *proxy,
    gint timeout_ms,
    gchar ***out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_add_match) (TpDBusDaemon *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_add_match (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_add_match callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_add_match (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_remove_match) (TpDBusDaemon *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_remove_match (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_remove_match callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_remove_match (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_get_name_owner) (TpDBusDaemon *proxy,
    const gchar *out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_get_name_owner (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_get_name_owner callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_get_name_owner (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    gchar **out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_list_queued_owners) (TpDBusDaemon *proxy,
    const gchar **out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_list_queued_owners (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_list_queued_owners callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_list_queued_owners (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    gchar ***out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_get_connection_unix_user) (TpDBusDaemon *proxy,
    guint out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_get_connection_unix_user (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_get_connection_unix_user callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_get_connection_unix_user (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint *out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_get_connection_unix_process_id) (TpDBusDaemon *proxy,
    guint out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_get_connection_unix_process_id (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_get_connection_unix_process_id callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_get_connection_unix_process_id (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    guint *out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_get_connection_se_linux_security_context) (TpDBusDaemon *proxy,
    const GArray *out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_get_connection_se_linux_security_context (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    tp_cli_dbus_daemon_callback_for_get_connection_se_linux_security_context callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_get_connection_se_linux_security_context (TpDBusDaemon *proxy,
    gint timeout_ms,
    const gchar *in0,
    GArray **out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_reload_config) (TpDBusDaemon *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_reload_config (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_reload_config callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_reload_config (TpDBusDaemon *proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_daemon_callback_for_get_id) (TpDBusDaemon *proxy,
    const gchar *out0,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_daemon_call_get_id (TpDBusDaemon *proxy,
    gint timeout_ms,
    tp_cli_dbus_daemon_callback_for_get_id callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_daemon_run_get_id (TpDBusDaemon *proxy,
    gint timeout_ms,
    gchar **out0,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_DBUS_DAEMON_H_INCLUDED) */
