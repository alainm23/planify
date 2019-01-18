/* We don't want gtkdoc scanning this file, it'll get
 * confused by seeing function definitions, so mark it as: */
/*<private_header>*/

static inline void
tp_cli_add_signals_for_channel_dispatch_operation (DBusGProxy *proxy)
{
  if (!tp_proxy_dbus_g_proxy_claim_for_signal_adding (proxy))
    return;
  dbus_g_proxy_add_signal (proxy, "ChannelLost",
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID);
  dbus_g_proxy_add_signal (proxy, "Finished",
      G_TYPE_INVALID);
}


static void
_tp_cli_channel_dispatch_operation_collect_args_of_channel_lost (DBusGProxy *proxy G_GNUC_UNUSED,
    const gchar *arg_Channel,
    const gchar *arg_Error,
    const gchar *arg_Message,
    TpProxySignalConnection *sc)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  GValueArray *args = g_value_array_new (3);
  GValue blank = { 0 };
  guint i;

  g_value_init (&blank, G_TYPE_INT);

  for (i = 0; i < 3; i++)
    g_value_array_append (args, &blank);
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_value_unset (args->values + 0);
  g_value_init (args->values + 0, DBUS_TYPE_G_OBJECT_PATH);
  g_value_set_boxed (args->values + 0, arg_Channel);

  g_value_unset (args->values + 1);
  g_value_init (args->values + 1, G_TYPE_STRING);
  g_value_set_string (args->values + 1, arg_Error);

  g_value_unset (args->values + 2);
  g_value_init (args->values + 2, G_TYPE_STRING);
  g_value_set_string (args->values + 2, arg_Message);

  tp_proxy_signal_connection_v0_take_results (sc, args);
}
static void
_tp_cli_channel_dispatch_operation_invoke_callback_for_channel_lost (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatch_operation_signal_callback_channel_lost callback =
      (tp_cli_channel_dispatch_operation_signal_callback_channel_lost) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      g_value_get_boxed (args->values + 0),
      g_value_get_string (args->values + 1),
      g_value_get_string (args->values + 2),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_dispatch_operation_connect_to_channel_lost (TpChannelDispatchOperation *proxy,
    tp_cli_channel_dispatch_operation_signal_callback_channel_lost callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[4] = {
      DBUS_TYPE_G_OBJECT_PATH,
      G_TYPE_STRING,
      G_TYPE_STRING,
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_DISPATCH_OPERATION, "ChannelLost",
      expected_types,
      G_CALLBACK (_tp_cli_channel_dispatch_operation_collect_args_of_channel_lost),
      _tp_cli_channel_dispatch_operation_invoke_callback_for_channel_lost,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_dispatch_operation_invoke_callback_for_finished (TpProxy *tpproxy,
    GError *error G_GNUC_UNUSED,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatch_operation_signal_callback_finished callback =
      (tp_cli_channel_dispatch_operation_signal_callback_finished) generic_callback;

  if (callback != NULL)
    callback (g_object_ref (tpproxy),
      user_data,
      weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);

  G_GNUC_END_IGNORE_DEPRECATIONS
  g_object_unref (tpproxy);
}
TpProxySignalConnection *
tp_cli_channel_dispatch_operation_connect_to_finished (TpChannelDispatchOperation *proxy,
    tp_cli_channel_dispatch_operation_signal_callback_finished callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object,
    GError **error)
{
  GType expected_types[1] = {
      G_TYPE_INVALID };

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (proxy), NULL);
  g_return_val_if_fail (callback != NULL, NULL);

  return tp_proxy_signal_connection_v0_new ((TpProxy *) proxy,
      TP_IFACE_QUARK_CHANNEL_DISPATCH_OPERATION, "Finished",
      expected_types,
      NULL, /* no args => no collector function */
      _tp_cli_channel_dispatch_operation_invoke_callback_for_finished,
      G_CALLBACK (callback), user_data, destroy,
      weak_object, error);
}

static void
_tp_cli_channel_dispatch_operation_collect_callback_handle_with (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_dispatch_operation_invoke_callback_handle_with (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatch_operation_callback_for_handle_with callback = (tp_cli_channel_dispatch_operation_callback_for_handle_with) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatchOperation *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatchOperation *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatch_operation_call_handle_with (TpChannelDispatchOperation *proxy,
    gint timeout_ms,
    const gchar *in_Handler,
    tp_cli_channel_dispatch_operation_callback_for_handle_with callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCH_OPERATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (proxy), NULL);
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
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "HandleWith",
          G_TYPE_STRING, in_Handler,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "HandleWith", iface,
          _tp_cli_channel_dispatch_operation_invoke_callback_handle_with,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "HandleWith",
              _tp_cli_channel_dispatch_operation_collect_callback_handle_with,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Handler,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_dispatch_operation_collect_callback_claim (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_dispatch_operation_invoke_callback_claim (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatch_operation_callback_for_claim callback = (tp_cli_channel_dispatch_operation_callback_for_claim) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatchOperation *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatchOperation *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatch_operation_call_claim (TpChannelDispatchOperation *proxy,
    gint timeout_ms,
    tp_cli_channel_dispatch_operation_callback_for_claim callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCH_OPERATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (proxy), NULL);
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
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "Claim",
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "Claim", iface,
          _tp_cli_channel_dispatch_operation_invoke_callback_claim,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "Claim",
              _tp_cli_channel_dispatch_operation_collect_callback_claim,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_INVALID));

      return data;
    }
}


static void
_tp_cli_channel_dispatch_operation_collect_callback_handle_with_time (DBusGProxy *proxy,
    DBusGProxyCall *call,
    gpointer user_data)
{
  GError *error = NULL;

  dbus_g_proxy_end_call (proxy, call, &error,
      G_TYPE_INVALID);
  tp_proxy_pending_call_v0_take_results (user_data, error,NULL);
}
static void
_tp_cli_channel_dispatch_operation_invoke_callback_handle_with_time (TpProxy *self,
    GError *error,
    GValueArray *args,
    GCallback generic_callback,
    gpointer user_data,
    GObject *weak_object)
{
  tp_cli_channel_dispatch_operation_callback_for_handle_with_time callback = (tp_cli_channel_dispatch_operation_callback_for_handle_with_time) generic_callback;

  if (error != NULL)
    {
      callback ((TpChannelDispatchOperation *) self,
          error, user_data, weak_object);
      g_error_free (error);
      return;
    }
  callback ((TpChannelDispatchOperation *) self,
      error, user_data, weak_object);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (args != NULL)
    g_value_array_free (args);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TpProxyPendingCall *
tp_cli_channel_dispatch_operation_call_handle_with_time (TpChannelDispatchOperation *proxy,
    gint timeout_ms,
    const gchar *in_Handler,
    gint64 in_UserActionTime,
    tp_cli_channel_dispatch_operation_callback_for_handle_with_time callback,
    gpointer user_data,
    GDestroyNotify destroy,
    GObject *weak_object)
{
  GError *error = NULL;
  GQuark interface = TP_IFACE_QUARK_CHANNEL_DISPATCH_OPERATION;
  DBusGProxy *iface;

  g_return_val_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (proxy), NULL);
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
            error, user_data, weak_object);

      if (destroy != NULL)
        destroy (user_data);

      g_error_free (error);
      return NULL;
    }

  if (callback == NULL)
    {
      dbus_g_proxy_call_no_reply (iface, "HandleWithTime",
          G_TYPE_STRING, in_Handler,
          G_TYPE_INT64, in_UserActionTime,
          G_TYPE_INVALID);
      return NULL;
    }
  else
    {
      TpProxyPendingCall *data;

      data = tp_proxy_pending_call_v0_new ((TpProxy *) proxy,
          interface, "HandleWithTime", iface,
          _tp_cli_channel_dispatch_operation_invoke_callback_handle_with_time,
          G_CALLBACK (callback), user_data, destroy,
          weak_object, FALSE);
      tp_proxy_pending_call_v0_take_pending_call (data,
          dbus_g_proxy_begin_call_with_timeout (iface,
              "HandleWithTime",
              _tp_cli_channel_dispatch_operation_collect_callback_handle_with_time,
              data,
              tp_proxy_pending_call_v0_completed,
              timeout_ms,
              G_TYPE_STRING, in_Handler,
              G_TYPE_INT64, in_UserActionTime,
              G_TYPE_INVALID));

      return data;
    }
}


/*
 * tp_cli_channel_dispatch_operation_add_signals:
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
tp_cli_channel_dispatch_operation_add_signals (TpProxy *self G_GNUC_UNUSED,
    guint quark,
    DBusGProxy *proxy,
    gpointer unused G_GNUC_UNUSED)
{
  if (quark == TP_IFACE_QUARK_CHANNEL_DISPATCH_OPERATION)
    tp_cli_add_signals_for_channel_dispatch_operation (proxy);
}
