/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_debug (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "NewDebugMessage",
      G_TYPE_DOUBLE,
      G_TYPE_STRING,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID);
}


static void
_tp_cli_debug_collect_args_of_new_debug_message (DBusGProxy *proxy G_GNUC_UNUSED,
    gdouble arg_time,
    const gchar *arg_domain,
    guint arg_level,
    const gchar *arg_message,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (4);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 4; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, G_TYPE_DOUBLE);
  g_value_set_double (args->values + 0, arg_time);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_domain);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_UINT);
  g_value_set_uint (args->values + 2, arg_level);

  g_value_unset (args->values + 3);
  g_value_init (args->values + 3, G_TYPE_STRING);
  g_value_set_string (args->values + 3, arg_message);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_debug_invoke_callback_for_new_debug_message (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_debug_signal_callback_new_debug_message callback =
      (tp_cli_debug_signal_callback_new_debug_message) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_double (args->values + 0),
      g_value_get_string (args->values + 1),
      g_value_get_uint (args->values + 2),
      g_value_get_string (args->values + 3),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_debug_connect_to_new_debug_message (TpDebugClient *proxy,
    tp_cli_debug_signal_callback_new_debug_message callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[5] = {
      G_TYPE_DOUBLE,
      G_TYPE_STRING,
      G_TYPE_UINT,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_DEBUG_CLIENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_DEBUG, "NewDebugMessage",
      expected_types,
      G_CALLBACK (_tp_cli_debug_collect_args_of_new_debug_message),
      _tp_cli_debug_invoke_callback_for_new_debug_message,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_debug_collect_callback_get_messages (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;
  GValueArray *args;
  GValue blank = { 0 };
  guint i;
  GPtrArray *out_Messages;

  dbus_g_proxy_end_call (proxy, call, &error,
      (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_DOUBLE, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))), &out_Messages,
      G_TYPE_INVALID);

  if (error != NULL)
    {
      tp_proxy_pending_call_v0_take_results (user_data, error,
          NULL);
      return;
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  args = g_value_array_new (1);
  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 1; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, (dbus_g_type_get_collection ("GPtrArray", (dbus_g_type_get_struct ("GValueArray", G_TYPE_DOUBLE, G_TYPE_STRING, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_INVALID)))));
  g_value_take_boxed (args->values + 0, out_Messages);
  tp_proxy_pending_call_v0_take_results (user_data, NULL, args);
}
static void
_tp_cli_debug_invoke_callback_get_messages (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_debug_callback_for_get_messages callback = (tp_cli_debug_callback_for_get_messages) generic_callback;

  if (error != NULL)
    {
      callback ((TpDebugClient *) self,
          NULL,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpDebugClient *) self,
      g_value_get_boxed (args->values + 0),
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_debug_call_get_messages (TpDebugClient *proxy,
    gint timeout_ms,
    tp_cli_debug_callback_for_get_messages callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_DEBUG;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_DEBUG_CLIENT (proxy), NULL);
  g_return_val_if_fail (callback != NULL || user_data == NULL, NULL);
  g_return_val_if_fail (callback != NULL || destroy == NULL, NULL);
  g_return_val_if_fail (callback != NULL || weak_object == NULL, NULL);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  iface = tp_proxy_borrow_interface_by_id (
      (TpProxy *) proxy,
      interface, &error);
  G_GNUC_END_IGNORE_DEPRECATIONS

  if (iface == NULL)
    {
      if (callback != NULL)
        callback (proxy,
            NULL,
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "GetMessages",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "GetMessages", iface,
          _tp_cli_debug_invoke_callback_get_messages,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "GetMessages",
              _tp_cli_debug_collect_callback_get_messages,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


/*
 * tp_cli_debug_add_signals:
 * @self: the #TpProxy
 * @quark: a quark whose string value is the interface
 *   name whose signals should be added
 * @proxy: the D-Bus proxy to which to add the signals
 * @unused: not used for anything
 *
 * Tell dbus-glib that @proxy has the signatures of all
 * signals on the given interface, if it's one we
 * support.
 *
 * This function should be used as a signal handler for
 * #TpProxy::interface-added.
 */
static void
tp_cli_debug_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_DEBUG)
    tp_cli_add_signals_for_debug (proxy);
}
