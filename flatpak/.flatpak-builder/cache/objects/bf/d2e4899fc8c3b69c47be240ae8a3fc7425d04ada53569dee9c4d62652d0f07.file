#ifndef TP_GEN_TP_CLI_GENERIC_H_INCLUDED
#define TP_GEN_TP_CLI_GENERIC_H_INCLUDED

G_BEGIN_DECLS

typedef void (*tp_cli_dbus_introspectable_callback_for_introspect) (TpProxy *proxy,
    const gchar *out_XML_Data,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_introspectable_call_introspect (gpointer proxy,
    gint timeout_ms,
    tp_cli_dbus_introspectable_callback_for_introspect callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_introspectable_run_introspect (gpointer proxy,
    gint timeout_ms,
    gchar **out_XML_Data,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_peer_callback_for_ping) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_peer_call_ping (gpointer proxy,
    gint timeout_ms,
    tp_cli_dbus_peer_callback_for_ping callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_peer_run_ping (gpointer proxy,
    gint timeout_ms,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_peer_callback_for_get_machine_id) (TpProxy *proxy,
    const gchar *out_Machine_UUID,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_peer_call_get_machine_id (gpointer proxy,
    gint timeout_ms,
    tp_cli_dbus_peer_callback_for_get_machine_id callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_peer_run_get_machine_id (gpointer proxy,
    gint timeout_ms,
    gchar **out_Machine_UUID,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_properties_signal_callback_properties_changed) (TpProxy *proxy,
    const gchar *arg_Interface_Name,
    GHashTable *arg_Changed_Properties,
    const gchar **arg_Invalidated_Properties,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_dbus_properties_connect_to_properties_changed (gpointer proxy,
    tp_cli_dbus_properties_signal_callback_properties_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_dbus_properties_callback_for_get) (TpProxy *proxy,
    const GValue *out_Value,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_properties_call_get (gpointer proxy,
    gint timeout_ms,
    const gchar *in_Interface_Name,
    const gchar *in_Property_Name,
    tp_cli_dbus_properties_callback_for_get callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_properties_run_get (gpointer proxy,
    gint timeout_ms,
    const gchar *in_Interface_Name,
    const gchar *in_Property_Name,
    GValue **out_Value,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_properties_callback_for_set) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_properties_call_set (gpointer proxy,
    gint timeout_ms,
    const gchar *in_Interface_Name,
    const gchar *in_Property_Name,
    const GValue *in_Value,
    tp_cli_dbus_properties_callback_for_set callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_properties_run_set (gpointer proxy,
    gint timeout_ms,
    const gchar *in_Interface_Name,
    const gchar *in_Property_Name,
    const GValue *in_Value,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_dbus_properties_callback_for_get_all) (TpProxy *proxy,
    GHashTable *out_Properties,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_dbus_properties_call_get_all (gpointer proxy,
    gint timeout_ms,
    const gchar *in_Interface_Name,
    tp_cli_dbus_properties_callback_for_get_all callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_dbus_properties_run_get_all (gpointer proxy,
    gint timeout_ms,
    const gchar *in_Interface_Name,
    GHashTable **out_Properties,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_properties_interface_signal_callback_properties_changed) (TpProxy *proxy,
    const GPtrArray *arg_Properties,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_properties_interface_connect_to_properties_changed (gpointer proxy,
    tp_cli_properties_interface_signal_callback_properties_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_properties_interface_signal_callback_property_flags_changed) (TpProxy *proxy,
    const GPtrArray *arg_Properties,
    gpointer user_data, GObject *weak_object);
TpProxySignalConnection *tp_cli_properties_interface_connect_to_property_flags_changed (gpointer proxy,
    tp_cli_properties_interface_signal_callback_property_flags_changed callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error);

typedef void (*tp_cli_properties_interface_callback_for_get_properties) (TpProxy *proxy,
    const GPtrArray *out_Values,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_properties_interface_call_get_properties (gpointer proxy,
    gint timeout_ms,
    const GArray *in_Properties,
    tp_cli_properties_interface_callback_for_get_properties callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_properties_interface_run_get_properties (gpointer proxy,
    gint timeout_ms,
    const GArray *in_Properties,
    GPtrArray **out_Values,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_properties_interface_callback_for_list_properties) (TpProxy *proxy,
    const GPtrArray *out_Available_Properties,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_properties_interface_call_list_properties (gpointer proxy,
    gint timeout_ms,
    tp_cli_properties_interface_callback_for_list_properties callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_properties_interface_run_list_properties (gpointer proxy,
    gint timeout_ms,
    GPtrArray **out_Available_Properties,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


typedef void (*tp_cli_properties_interface_callback_for_set_properties) (TpProxy *proxy,
    const GError *error, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_cli_properties_interface_call_set_properties (gpointer proxy,
    gint timeout_ms,
    const GPtrArray *in_Properties,
    tp_cli_properties_interface_callback_for_set_properties callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object);

#ifndef TP_DISABLE_DEPRECATED
gboolean tp_cli_properties_interface_run_set_properties (gpointer proxy,
    gint timeout_ms,
    const GPtrArray *in_Properties,
    GError **error,
    GMainLoop **loop) _TP_GNUC_DEPRECATED;
#endif /* not TP_DISABLE_DEPRECATED */


G_END_DECLS

#endif /* defined (TP_GEN_TP_CLI_GENERIC_H_INCLUDED) */
